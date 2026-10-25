//
//  ViewController.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 13/09/26.
//

import UIKit
import MapKit
import RevealingSplashView
import CoreLocation
import Firebase
import FirebaseAuth



class HomeVC: UIViewController, Alertable{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var actionBtton: RoundedShadowButton!
    @IBOutlet weak var centerMapBton: UIButton!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var destinationCircle: CircleView!

    @IBOutlet weak var cancelBton: UIButton!

    var delegate: CenterVCDelegate?

    var manager: CLLocationManager?

    // Computada: siempre refleja la sesión actual (antes se leía una sola vez al crear el VC)
    var currentUserId: String? { Auth.auth().currentUser?.uid }

    var regionRadius: CLLocationDistance = 1000

    let revealingSplashView =  RevealingSplashView(iconImage: .launchScreenIcon, iconInitialSize: CGSize(width: 80, height: 80), backgroundColor: .white)

    var tableView =  UITableView()

    var matchingItems: [MKMapItem] = [MKMapItem]()
    var selectedItemPlacemark: MKPlacemark? = nil

    var actionForButton: ButtonAction = .requestRide
    var route: MKRoute!

    // Rol del usuario, se llena una sola vez en viewWillAppear
    private var cachedIsDriver: Bool?

    // Observers (para no duplicarlos y poder quitarlos)
    private var driversHandle: DatabaseHandle?
    private var tripRef: DatabaseReference?
    private var tripHandle: DatabaseHandle?
    private var tripRemovedHandle: DatabaseHandle?

    // Para hacer zoom una sola vez al iniciar el viaje
    private var hasZoomedForActiveTrip = false
    private var isTripInProgressShown = false

    // MARK: - Ciclo de vida

    override func viewDidLoad() {
        super.viewDidLoad()

        //delegados
        mapView.delegate = self
        destinationTextField.delegate = self

        mapView.showsUserLocation = true

        manager = CLLocationManager()
        manager?.delegate = self
        manager?.desiredAccuracy = kCLLocationAccuracyBest

        checkLocationAuthStatus()

        cancelBton.alpha = 0.0

        self.view.addSubview(revealingSplashView)
        revealingSplashView.animationType = SplashAnimationType.heartBeat
        revealingSplashView.startAnimation()
        revealingSplashView.heartAttack = true

        observeDrivers()
        observeIncomingTrips()
        observeTripRemoval()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let uid = currentUserId else { return }

        DataService.instance.userIsDriver(userKey: uid) { [weak self] isDriver in
            guard let self = self else { return }
            self.cachedIsDriver = (isDriver == true)

            if isDriver == true {
                self.buttonsForDriver(areHidden: true)
                self.showActiveTripForDriver(uid: uid)
            } else {
                self.connectUserAndDriverForTrip()   // tiene guard contra observers duplicados
            }
        }
    }

    deinit {
        if let h = driversHandle { DataService.instance.REF_DRIVERS.removeObserver(withHandle: h) }
        if let h = tripHandle { tripRef?.removeObserver(withHandle: h) }
        if let h = tripRemovedHandle { DataService.instance.REF_TRIPS.removeObserver(withHandle: h) }
    }

    // MARK: - Observers

    /// Conductores en el mapa (+ zoom una sola vez cuando el pasajero ya tiene viaje)
    private func observeDrivers() {
        driversHandle = DataService.instance.REF_DRIVERS.observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            self.updateDriverAnnotations(from: snapshot)

            guard let uid = self.currentUserId, !self.hasZoomedForActiveTrip else { return }
            DataService.instance.passengerIsOnTrip(passengerKey: uid) { [weak self] isOnTrip, driverKey, _ in
                guard let self = self, isOnTrip == true, !self.hasZoomedForActiveTrip else { return }
                self.hasZoomedForActiveTrip = true
                self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
            }
        }
    }

    /// Solicitudes nuevas para el conductor (abre PickupVC)
    private func observeIncomingTrips() {
        UpdateService.instance.observeTrips { [weak self] tripDict in
            guard let self = self,
                  let tripDict = tripDict,
                  let coords = tripDict["pickupCoordinate"] as? [Double], coords.count == 2,
                  let passengerKey = tripDict["passengerKey"] as? String,
                  let accepted = tripDict["tripIsAccepted"] as? Bool, accepted == false,
                  let uid = self.currentUserId
            else { return }

            DataService.instance.driverIsAvailable(key: uid) { [weak self] available in
                guard let self = self,
                      available == true,
                      self.presentedViewController == nil      // no presentar dos veces
                else { return }

                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                guard let pickupVC = storyboard.instantiateViewController(withIdentifier: "PickupVC") as? PickupVC else { return }

                pickupVC.initData(coordinate: CLLocationCoordinate2D(latitude: coords[0], longitude: coords[1]),
                                  passengerKey: passengerKey)
                self.present(pickupVC, animated: true)
            }
        }
    }

    /// Cuando se borra MI viaje (cancelado o terminado) se limpia la pantalla
    private func observeTripRemoval() {
        guard tripRemovedHandle == nil else { return }

        tripRemovedHandle = DataService.instance.REF_TRIPS.observe(.childRemoved) { [weak self] snap in
            guard let self = self, let uid = self.currentUserId else { return }

            let dict = snap.value as? [String: AnyObject]
            let tripDriverKey = dict?["driverKey"] as? String

            // solo reaccionar a MI viaje (como pasajero o como conductor)
            guard snap.key == uid || tripDriverKey == uid else { return }

            if let driverKey = tripDriverKey {
                DataService.instance.REF_DRIVERS.child(driverKey)
                    .updateChildValues(["driverIsOnTrip": false])
            }

            self.hasZoomedForActiveTrip = false

            DataService.instance.userIsDriver(userKey: uid) { [weak self] isDriver in
                guard let self = self else { return }
                self.removeOverlaysAndAnnotations(forDrivers: false, forPassegers: true)

                if isDriver != true {
                    self.cancelBton.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                    self.actionBtton.animateButton(shouldLoad: false, withMessage: "REQUEST RIDE")
                    self.actionBtton.isUserInteractionEnabled = true
                    self.actionForButton = .requestRide

                    self.destinationTextField.isUserInteractionEnabled = true
                    self.destinationTextField.text = ""

                    self.centerMapOnUserLocation()
                }
            }
        }
    }

    // MARK: - Conductor: viaje activo

    private func showActiveTripForDriver(uid: String) {
        DataService.instance.driverIsOnTrip(driverKey: uid) { [weak self] isOnTrip, _, tripKey in
            guard let self = self, isOnTrip == true, let tripKey = tripKey else { return }

            DataService.instance.REF_TRIPS.child(tripKey).child("pickupCoordinate")
                .observeSingleEvent(of: .value) { [weak self] snap in
                    guard let self = self,
                          let c = snap.value as? [Double], c.count == 2 else { return }

                    let coord = CLLocationCoordinate2D(latitude: c[0], longitude: c[1])
                    let placemark = MKPlacemark(coordinate: coord)

                    self.removeOverlaysAndAnnotations(forDrivers: false, forPassegers: true)
                    self.dropPinFor(placeMark: placemark)
                    self.searchMapKitForResultsWithPolyline(forOriginMapItem: nil,
                                                            withDestinationMapItem: MKMapItem(placemark: placemark))
                    self.setCustomRegion(forAnnotationType: .pickup, withCoordinate: coord)

                    self.actionForButton = .getDirectionsToPassenger
                    self.actionBtton.setTitle("Get directions", for: .normal)
                    self.buttonsForDriver(areHidden: false)
                }
        }
    }

    // MARK: - Pasajero: viaje aceptado

    /// Solo se llama para pasajeros (ver viewWillAppear).
    func connectUserAndDriverForTrip() {
        guard let uid = currentUserId else { return }
        guard tripHandle == nil else { return }   // evita observers duplicados

        let ref = DataService.instance.REF_TRIPS.child(uid)
        tripRef = ref

        tripHandle = ref.observe(.value) { [weak self] snap in
            guard let self = self,
                  let trip = snap.value as? [String: AnyObject]
            else { return }

            // 1) Viaje en curso: ruta al destino (solo una vez)
            if trip["tripIsInProgress"] as? Bool == true {
                guard !self.isTripInProgressShown,
                      let dest = trip["destinationCoordinate"] as? [Double], dest.count == 2
                else { return }
                self.isTripInProgressShown = true

                let destinationCoordinate = CLLocationCoordinate2D(latitude: dest[0], longitude: dest[1])
                let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)

                self.removeOverlaysAndAnnotations(forDrivers: true, forPassegers: true)
                self.dropPinFor(placeMark: destinationPlacemark)
                self.searchMapKitForResultsWithPolyline(forOriginMapItem: nil,
                                                        withDestinationMapItem: MKMapItem(placemark: destinationPlacemark))
                self.actionBtton.setTitle("ON TRIP", for: .normal)
                return
            }

            // 2) Viaje aceptado: ruta del conductor al pickup
            guard trip["tripIsAccepted"] as? Bool == true,
                  let driverId = trip["driverKey"] as? String,
                  let p = trip["pickupCoordinate"] as? [Double], p.count == 2
            else { return }

            let pickup = CLLocationCoordinate2D(latitude: p[0], longitude: p[1])
            let pickupItem = MKMapItem(placemark: MKPlacemark(coordinate: pickup))

            DataService.instance.REF_DRIVERS.child(driverId).child("coordinate")
                .observeSingleEvent(of: .value) { [weak self] snap in
                    guard let self = self,
                          !self.isTripInProgressShown,   // el viaje pudo empezar mientras llegaba la respuesta
                          let d = snap.value as? [Double], d.count == 2 else { return }

                    let driverItem = MKMapItem(placemark: MKPlacemark(
                        coordinate: CLLocationCoordinate2D(latitude: d[0], longitude: d[1])))

                    // limpiar justo antes de dibujar (evita pines y rutas dobles)
                    self.removeOverlaysAndAnnotations(forDrivers: false, forPassegers: true)
                    self.mapView.addAnnotation(PassengerAnnotation(coordinate: pickup, key: uid))
                    self.searchMapKitForResultsWithPolyline(forOriginMapItem: driverItem,
                                                            withDestinationMapItem: pickupItem)

                    self.actionBtton.animateButton(shouldLoad: false, withMessage: "DRIVER COMING")
                    self.actionBtton.isUserInteractionEnabled = false
                }
        }
    }
    // MARK: - Ubicación / botones

    func checkLocationAuthStatus() {
        guard let manager = manager else { return }
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse,
             .authorizedAlways:
            manager.startUpdatingLocation()
        @unknown default:
            break
        }
    }

    func buttonsForDriver(areHidden: Bool){
        if areHidden{
            self.actionBtton.fadeTo(alphaValue: 0.0, withDuration: 0.2)
            self.cancelBton.fadeTo(alphaValue: 0.0, withDuration: 0.2)
            self.centerMapBton.fadeTo(alphaValue: 0.0, withDuration: 0.2)
            self.actionBtton.isHidden = true
            self.cancelBton.isHidden = true
            self.centerMapBton.isHidden = true
        } else {
            self.actionBtton.fadeTo(alphaValue: 1.0, withDuration: 0.2)
            self.cancelBton.fadeTo(alphaValue: 1.0, withDuration: 0.2)
            self.centerMapBton.fadeTo(alphaValue: 1.0, withDuration: 0.2)
            self.actionBtton.isHidden = false
            self.cancelBton.isHidden = false
            self.centerMapBton.isHidden = false
        }
    }

    // MARK: - Anotaciones de conductores

    /// Versión que descarga por su cuenta (por si la llamas desde otro lado).
    func loadDriverAnnotationsFromFB(){
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value) { [weak self] snapshot in
            self?.updateDriverAnnotations(from: snapshot)
        }
    }

    /// Usa el snapshot que ya tienes, sin volver a descargar.
    func updateDriverAnnotations(from snapshot: DataSnapshot) {
        guard let drivers = snapshot.children.allObjects as? [DataSnapshot] else { return }

        for driver in drivers {
            guard driver.hasChild("userIsDriver"), driver.hasChild("coordinate") else { continue }

            if driver.childSnapshot(forPath: "isPickupModeEnabled").value as? Bool == true {
                guard let c = driver.childSnapshot(forPath: "coordinate").value as? [Double], c.count == 2 else { continue }
                let coordinate = CLLocationCoordinate2D(latitude: c[0], longitude: c[1])

                let existing = mapView.annotations
                    .compactMap { $0 as? DriverAnnotation }
                    .first { $0.key == driver.key }

                if let existing = existing {
                    existing.update(annotationPosition: existing, withCoordinate: coordinate)
                } else {
                    mapView.addAnnotation(DriverAnnotation(coordinate: coordinate, withKey: driver.key))
                }
            } else {
                for annotation in mapView.annotations {
                    if let a = annotation as? DriverAnnotation, a.key == driver.key {
                        mapView.removeAnnotation(a)
                    }
                }
            }
        }
    }

    func centerMapOnUserLocation(){
        let coordinateRegion = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    // MARK: - IBActions

    @IBAction func cancelBtonWasPressed(_ sender: Any) {
        guard let uid = currentUserId else { return }

        if cachedIsDriver == true {
            DataService.instance.driverIsOnTrip(driverKey: uid) { isOnTrip, driverKey, tripKey in
                if isOnTrip == true, let tripKey = tripKey, let driverKey = driverKey {
                    UpdateService.instance.cancelTrip(withPassengerKey: tripKey, forDriverKey: driverKey)
                }
            }
        } else {
            DataService.instance.passengerIsOnTrip(passengerKey: uid) { isOnTrip, driverKey, _ in
                if isOnTrip == true, let driverKey = driverKey {
                    UpdateService.instance.cancelTrip(withPassengerKey: uid, forDriverKey: driverKey)
                } else {
                    UpdateService.instance.cancelTrip(withPassengerKey: uid, forDriverKey: nil)
                }
            }
        }

        self.actionBtton.isUserInteractionEnabled = true
    }

    @IBAction func centerMapBtonPressed(_ sender: Any) {
        guard let uid = currentUserId else { return }

        DataService.instance.REF_USERS.child(uid).observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }

            if snapshot.hasChild("tripCoordinate") {
                self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: false, withKey: nil)
            } else {
                self.centerMapOnUserLocation()
            }
            self.centerMapBton.fadeTo(alphaValue: 0.0, withDuration: 0.2)
        }
    }

    @IBAction func actionButtonWasPressed(_ sender: Any) {
        buttonSelector(forAction: actionForButton)
    }

    @IBAction func menuBtnWasPressed(_ sender: Any) {
        delegate?.toggleLeftPanel()
    }

    func buttonSelector(forAction action: ButtonAction){
        switch action {
        case .requestRide:
            if destinationTextField.text != ""{
                UpdateService.instance.updateTripsWithCoordinateUponRequest()
                actionBtton.animateButton(shouldLoad: true, withMessage: nil)
                cancelBton.fadeTo(alphaValue: 1.0, withDuration: 0.2)
                self.view.endEditing(true)
                destinationTextField.isUserInteractionEnabled = false
            }
        case .getDirectionsToPassenger:
            guard let uid = currentUserId else { return }
            DataService.instance.driverIsOnTrip(driverKey: uid) { isOnTrip, _, tripKey in
                guard isOnTrip == true, let tripKey = tripKey else { return }

                // observeSingleEvent: antes era .observe y se reabría Maps en cada cambio
                DataService.instance.REF_TRIPS.child(tripKey).child("pickupCoordinate")
                    .observeSingleEvent(of: .value) { snap in
                        guard let c = snap.value as? [Double], c.count == 2 else { return }

                        let coordinate = CLLocationCoordinate2D(latitude: c[0], longitude: c[1])
                        let pickupMapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
                        pickupMapItem.name = "Passenger Pickup Point"
                        pickupMapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                    }
            }
        case .getDirectionsToDestination:
            DataService.instance.driverIsOnTrip(driverKey: self.currentUserId!, handler: { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    DataService.instance.REF_TRIPS.child(tripKey!).child("destinationCoordinate").observe(.value, with: { (snapshot) in
                        let destinationCoordinateArray = snapshot.value as! NSArray
                        let destinationCoordinate = CLLocationCoordinate2D(latitude: destinationCoordinateArray[0] as! CLLocationDegrees, longitude: destinationCoordinateArray[1] as! CLLocationDegrees)
                        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
                        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)

                        destinationMapItem.name = "Passenger Destination"
                        destinationMapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
                    })
                }
            })
            
            
        case .startTrip:
            guard let uid = currentUserId else { return }
            DataService.instance.driverIsOnTrip(driverKey: uid) { [weak self] isOnTrip, _, tripKey in
                guard let self = self, isOnTrip == true, let tripKey = tripKey else { return }

                self.removeOverlaysAndAnnotations(forDrivers: false, forPassegers: false)

                DataService.instance.REF_TRIPS.child(tripKey).updateChildValues(["tripIsInProgress": true])

                DataService.instance.REF_TRIPS.child(tripKey).child("destinationCoordinate")
                    .observeSingleEvent(of: .value) { [weak self] snap in
                        guard let self = self,
                              let c = snap.value as? [Double], c.count == 2 else { return }

                        let destination = CLLocationCoordinate2D(latitude: c[0], longitude: c[1])
                        let placemark = MKPlacemark(coordinate: destination)

                        self.dropPinFor(placeMark: placemark)
                        self.searchMapKitForResultsWithPolyline(forOriginMapItem: nil,
                                                                withDestinationMapItem: MKMapItem(placemark: placemark))
                        self.setCustomRegion(forAnnotationType: .destination, withCoordinate: destination)

                        self.actionForButton = .getDirectionsToDestination
                        self.actionBtton.setTitle("GET DIRECTIONS", for: .normal)
                    }
            }
        case .endTrip:
            DataService.instance.driverIsOnTrip(driverKey: self.currentUserId!) { isOnTrip, driverKey, tripKey in
                if isOnTrip == true {
                    UpdateService.instance.cancelTrip(withPassengerKey: tripKey!, forDriverKey: driverKey!)
                    self.buttonsForDriver(areHidden: true)
                    
                }
            }
        }
    }
}



//MARK: EXTENSIONS

extension HomeVC: UITextFieldDelegate{
    func textFieldDidBeginEditing(_ textField: UITextField) {

        if textField == destinationTextField{
            tableView.frame = CGRect(x: 20, y: view.frame.height, width: view.frame.width - 40, height: view.frame.height - 150)
            tableView.layer.cornerRadius = 5.0
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "locationCell")

            tableView.delegate = self
            tableView.dataSource = self

            tableView.tag = 18
            tableView.rowHeight = 60
            view.addSubview(tableView)


            animateTableView(shouldShow: true)

            UIView.animate(withDuration: 0.2) {
                self.destinationCircle.backgroundColor = UIColor.red
                self.destinationCircle.borderColor = UIColor.init(red: 199 / 255, green: 0 / 255, blue: 0 / 255, alpha: 1.0)
            }
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == destinationTextField{
            //perform search
            performSearch()
            shouldPresentLoadingView(true)
            view.endEditing(true)
        }
        return true
    }

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        matchingItems = []
        tableView.reloadData()


        //delete trip coordinate with cancel trip
        if let uid = currentUserId {
            DataService.instance.REF_USERS.child(uid).child("tripCoordinate").removeValue()
        }
        mapView.removeOverlays(mapView.overlays)
        for annotation in mapView.annotations{
            if let annotation = annotation as? MKPointAnnotation{
                mapView.removeAnnotation(annotation)
            } else if annotation.isKind(of: PassengerAnnotation.self){
                mapView.removeAnnotation(annotation)
            }

        }

        centerMapOnUserLocation()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == destinationTextField{
            if destinationTextField.text == "" {
                UIView.animate(withDuration: 0.2) {
                    self.destinationCircle.backgroundColor = UIColor.lightGray
                    self.destinationCircle.borderColor = UIColor.darkGray

                }
            }
        }
    }

    func animateTableView(shouldShow: Bool) {
        if shouldShow {
            UIView.animate(withDuration: 0.2) {
                self.tableView.frame = CGRect(x: 20,
                                              y: 240,                       // debajo de la caja "Where are you going?"
                                              width: self.view.frame.width - 40,
                                              height: 600)                  // altura que tú quieras
            }


        } else{
            UIView.animate(withDuration: 0.2) {
                self.tableView.frame = CGRect(x: 20,
                                              y: 240,                       // debajo de la caja "Where are you going?"
                                              width: self.view.frame.width - 40,
                                              height: 600)                  // altura que tú quieras
            } completion: { finished in
                for subview in self.view.subviews{
                    if subview.tag == 18{
                        subview.removeFromSuperview()
                    }
                }
            }

        }
    }
}

extension HomeVC : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "locationCell")
        let mapItem = matchingItems[indexPath.row]
        cell.textLabel?.text = mapItem.name
        cell.detailTextLabel?.text = mapItem.placemark.title
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // sin ubicación o sin sesión no hay viaje que pedir
        guard let passengerCoordinate = manager?.location?.coordinate,
              let uid = currentUserId else {
            showAlert("We can't find your location yet. Try again in a moment.")
            return
        }

        shouldPresentLoadingView(true)

        let passengerAnnotation = PassengerAnnotation(coordinate: passengerCoordinate, key: uid)
        mapView.addAnnotation(passengerAnnotation)

        //same title of field destination
        destinationTextField.text = tableView.cellForRow(at: indexPath)?.textLabel?.text

        //save to firebase 'tripCoordinate'
        let selectedMapItem = matchingItems[indexPath.row]
        DataService.instance.REF_USERS.child(uid).updateChildValues(["tripCoordinate": [selectedMapItem.placemark.coordinate.latitude, selectedMapItem.placemark.coordinate.longitude]])


        dropPinFor(placeMark: selectedMapItem.placemark)

        searchMapKitForResultsWithPolyline(forOriginMapItem: nil, withDestinationMapItem: selectedMapItem)

        animateTableView(shouldShow: false)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if destinationTextField.text == "" {
            animateTableView(shouldShow: false)
        }
    }
}

extension HomeVC: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {

            mapView.showsUserLocation = true
            manager.startUpdatingLocation()
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {

        guard let location = locations.last else { return }

        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: regionRadius * 2,
            longitudinalMeters: regionRadius * 2
        )

        mapView.setRegion(region, animated: true)

        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let uid = currentUserId else { return }

        DataService.instance.driverIsOnTrip(driverKey: uid) { [weak self] isOnTrip, _, _ in
            guard let self = self, isOnTrip == true else { return }

            if region.identifier == "pickup" {
                self.actionForButton = .startTrip
                self.actionBtton.setTitle("START TRIP", for: .normal)
            } else if region.identifier == "destination" {
                self.actionForButton = .endTrip
                self.cancelBton.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                self.cancelBton.isHidden = true
                self.actionBtton.setTitle("END TRIP", for: .normal)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let uid = currentUserId else { return }

        DataService.instance.driverIsOnTrip(driverKey: uid) { [weak self] isOnTrip, _, _ in
            guard let self = self, isOnTrip == true else { return }

            if region.identifier == "pickup" || region.identifier == "destination" {
                // aquí irá la acción que carga las direcciones
                self.actionBtton.setTitle("GET DIRECTIONS", for: .normal)
            }
        }
    }
}

extension HomeVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        UpdateService.instance.updateUserLocation(withCoordinate: userLocation.coordinate)
        UpdateService.instance.updateDriverLocation(withCoordinate: userLocation.coordinate)

        // usa el rol guardado en vez de consultarlo en cada actualización del GPS
        guard let uid = currentUserId, let isDriver = cachedIsDriver else { return }

        if isDriver {
            DataService.instance.driverIsOnTrip(driverKey: uid) { [weak self] isOnTrip, driverKey, _ in
                guard let self = self else { return }
                if isOnTrip == true {
                    self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                } else {
                    self.centerMapOnUserLocation()
                }
            }
        } else {
            DataService.instance.passengerIsOnTrip(passengerKey: uid) { [weak self] isOnTrip, _, _ in
                if isOnTrip == true {
                    self?.centerMapOnUserLocation()
                }
            }
        }
    }


    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation{
            let identifier = "driver"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: "driverAnnotation")
            return view
        } else if let annotation = annotation as? PassengerAnnotation{
            let identifier = "passenger"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: "currentLocationAnnotation")
            return view
        } else if let annotation = annotation as? MKPointAnnotation{
            let identifer = "destination"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifer)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifer)
            } else {
                annotationView?.annotation = annotation
            }
            annotationView?.image = UIImage(named: "destinationAnnotation")
            return annotationView
        }
        return nil

    }


    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        centerMapBton.fadeTo(alphaValue: 1.0, withDuration: 0.2)
    }

    /// El renderer solo dibuja: usa el overlay que recibe y no tiene efectos secundarios.
    func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer(overlay: overlay)
        }

        let linearRenderer = MKPolylineRenderer(polyline: polyline)
        linearRenderer.strokeColor = UIColor(red: 216/255, green: 71/255, blue: 30/255, alpha: 0.75)
        linearRenderer.lineWidth = 3
        return linearRenderer
    }

    func performSearch(){
        matchingItems.removeAll()
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = destinationTextField.text
        request.region = mapView.region

        let search = MKLocalSearch(request: request)

        search.start { [weak self] response, error in
            guard let self = self else { return }

            if error != nil {
                self.shouldPresentLoadingView(false)
                self.showAlert("An error ocurred, please search something real")
                return
            }

            guard let items = response?.mapItems, !items.isEmpty else {
                self.shouldPresentLoadingView(false)
                self.showAlert("No result! Please search again..")
                return
            }

            self.matchingItems.append(contentsOf: items)
            self.tableView.reloadData()
            self.shouldPresentLoadingView(false)
        }

    }


    func dropPinFor(placeMark: MKPlacemark){
        selectedItemPlacemark = placeMark

        for annotation in mapView.annotations{
            if annotation.isKind(of: MKPointAnnotation.self){
                mapView.removeAnnotation(annotation)
            }
        }

        let annotation = MKPointAnnotation()
        annotation.coordinate = placeMark.coordinate
        mapView.addAnnotation(annotation)
    }

    func searchMapKitForResultsWithPolyline(forOriginMapItem originMapItem: MKMapItem?, withDestinationMapItem destinationMapItem: MKMapItem){
        let request = MKDirections.Request()

        if originMapItem == nil {
            request.source = MKMapItem.forCurrentLocation()
        } else {
            request.source = originMapItem
        }


        request.destination = destinationMapItem
        request.transportType = MKDirectionsTransportType.automobile

        let directions = MKDirections(request: request)

        directions.calculate { [weak self] response, error in
            guard let self = self else { return }

            // Antes: error as! String -> crash siempre que fallaba la ruta
            guard let route = response?.routes.first else {
                self.shouldPresentLoadingView(false)
                self.showAlert(error?.localizedDescription ?? "No route found")
                return
            }

            self.route = route //the first route more faster
            self.mapView.addOverlay(route.polyline)

            // efectos que antes estaban dentro del renderer
            self.shouldPresentLoadingView(false)
            AppDelegate.getAppDelegate().window?.rootViewController?.shouldPresentLoadingView(false)
            self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: false, withKey: nil)
        }
    }

    /// Ajusta el zoom del mapa para que se vean todas las anotaciones
    /// (excepto las de conductores, salvo el del viaje activo) dentro de la pantalla.
    func zoom(toFitAnnotationsFromMapView mapView: MKMapView, forActiveTripWithDriver: Bool, withKey key: String?) {
        if mapView.annotations.isEmpty { return }

        // Empezamos con valores "imposibles" para que cualquier coordenada real los reemplace.
        // topLeft = esquina noroeste, bottomRight = esquina sureste
        var topLeftCoordinate = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        var foundAny = false

        for annotation in mapView.annotations {
            // Los conductores se ignoran, salvo el del viaje activo
            if let driverAnnotation = annotation as? DriverAnnotation {
                guard forActiveTripWithDriver, driverAnnotation.key == key else { continue }
            }

            foundAny = true
            topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)         // más al oeste
            topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)            // más al norte
            bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude) // más al este
            bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)    // más al sur
        }

        // Si no hubo nada que encuadrar, no mover el mapa a coordenadas basura
        guard foundAny else { return }

        // Centro = punto medio entre las dos esquinas
        let center = CLLocationCoordinate2D(
            latitude: topLeftCoordinate.latitude - (topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 0.5,
            longitude: topLeftCoordinate.longitude + (bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 0.5
        )

        // Span = tamaño del rectángulo x 2.0, para dejar margen y que los pines no queden pegados al borde
        let span = MKCoordinateSpan(
            latitudeDelta: fabs(topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 2.0,
            longitudeDelta: fabs(bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 2.0
        )

        var region = MKCoordinateRegion(center: center, span: span)

        // Ajusta la región al aspecto real del mapa en pantalla
        region = mapView.regionThatFits(region)
        mapView.setRegion(region, animated: true)
    }

    func removeOverlaysAndAnnotations(forDrivers: Bool?, forPassegers: Bool?){
        for annotation in mapView.annotations{
            if let annotation = annotation as? MKPointAnnotation{
                mapView.removeAnnotation(annotation)
            }

            if forPassegers == true{
                if let annotation = annotation as? PassengerAnnotation{
                    mapView.removeAnnotation(annotation)
                }
            }
            if forDrivers == true{
                if let annotation = annotation as? DriverAnnotation{
                    mapView.removeAnnotation(annotation)
                }
            }
        }

        for overlay in mapView.overlays {
            if overlay is MKPolyline {
                mapView.removeOverlay(overlay)
            }
        }
    }


    func setCustomRegion(forAnnotationType type: AnnotationType, withCoordinate coordinate: CLLocationCoordinate2D){
        if type == .pickup{
            let pickupRegion = CLCircularRegion(center: coordinate, radius: 100, identifier: "pickup")
            manager?.startMonitoring(for: pickupRegion)
        } else if type == .destination{

            let destionationRegion = CLCircularRegion(center: coordinate, radius: 100, identifier: "destination")
            manager?.startMonitoring(for: destionationRegion)
        }
    }
}


