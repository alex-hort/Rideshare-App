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
    var currentUserId = Auth.auth().currentUser?.uid
    
    var regionRadius: CLLocationDistance = 1000
    
    let revealingSplashView =  RevealingSplashView(iconImage: .launchScreenIcon, iconInitialSize: CGSize(width: 80, height: 80), backgroundColor: .white)
    
    var tableView =  UITableView()
    
    var matchingItems: [MKMapItem] = [MKMapItem]()
    var selectedItemPlacemark: MKPlacemark? = nil
    var route: MKRoute!
    
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
        
        DataService.instance.REF_DRIVERS.observe(.value) { snapshot in
            self.loadDriverAnnotationsFromFB()
            DataService.instance.passengerIsOnTrip(passengerKey: self.currentUserId!) { isOnTrip, driverKey, tripKey in
                if isOnTrip == true{
                    self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                }
            }
        }


        self.view.addSubview(revealingSplashView)
        revealingSplashView.animationType = SplashAnimationType.heartBeat
        revealingSplashView.startAnimation()
        revealingSplashView.heartAttack = true
        
        
        UpdateService.instance.observeTrips { tripDic in
            if let tripDict = tripDic{
                let pickupCoordinateArray = tripDic?["pickupCoordinate"] as! NSArray
                let tripKey = tripDic?["passengerKey"] as! String
                let acceptanceStatus = tripDic?["tripIsAccepted"] as! Bool
                
                
                if acceptanceStatus == false{
                    DataService.instance.driverIsAvailable(key: self.currentUserId!) { available in
                        if let available = available {
                            if available == true{
                                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                                let pickupVC = storyboard.instantiateViewController(withIdentifier: "PickupVC") as? PickupVC
                                pickupVC?.initData(coordinate: CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees), passengerKey: tripKey)
                                self.present(pickupVC!, animated: true)
                            }
                           
                        }
                    }
                }
            }
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DataService.instance.driverIsOnTrip(driverKey: self.currentUserId!) { isOnTrip, driverKey, tripKey in
            if isOnTrip == true {
                DataService.instance.REF_TRIPS.observeSingleEvent(of: .value, with: { (tripSnapshot) in
                    if let tripSnapshot = tripSnapshot.children.allObjects as? [DataSnapshot] {
                        for trip in tripSnapshot {
                            if trip.childSnapshot(forPath: "driverKey").value as? String == self.currentUserId! {
                                let pickupCoordinateArray = trip.childSnapshot(forPath: "pickupCoordinate").value as! NSArray
                                let pickupCoordinate = CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees)
                                let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)

                                // Limpia el mapa antes de pintar el nuevo pin y la ruta
                                self.removeOverlaysAndAnnotations(forDrivers: false, forPassegers: true)
                                self.dropPinFor(placeMark: pickupPlacemark)
                                self.searchMapKitForResultsWithPolyline(forOriginMapItem: nil, withDestinationMapItem: MKMapItem(placemark: pickupPlacemark))
                            }
                        }
                    }
                })
            }
        }

        DataService.instance.driverIsAvailable(key: self.currentUserId!, handler: { (status) in
            if status == false {
                DataService.instance.REF_TRIPS.observeSingleEvent(of: .value, with: { (tripSnapshot) in
                    if let tripSnapshot = tripSnapshot.children.allObjects as? [DataSnapshot] {
                        for trip in tripSnapshot {
                            if trip.childSnapshot(forPath: "driverKey").value as? String == self.currentUserId! {
                                let pickupCoordinateArray = trip.childSnapshot(forPath: "pickupCoordinate").value as! NSArray
                                let pickupCoordinate = CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees)
                                let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)

                                // Limpia el mapa antes de pintar el nuevo pin y la ruta
                                self.removeOverlaysAndAnnotations(forDrivers: false, forPassegers: true)
                                self.dropPinFor(placeMark: pickupPlacemark)
                                self.searchMapKitForResultsWithPolyline(forOriginMapItem: nil, withDestinationMapItem: MKMapItem(placemark: pickupPlacemark))
                            }
                        }
                    }
                })
            }
        })

        DataService.instance.REF_TRIPS.observe(.childRemoved) { removeTripSnapshot in
            let removedTripDict = removeTripSnapshot.value as? [String: AnyObject]
            if removedTripDict?["driverKey"] != nil {
                DataService.instance.REF_DRIVERS.child(removedTripDict?["driverKey"] as! String).updateChildValues(["driverIsOnTrip": false])
            }
                
            DataService.instance.userIsDriver(userKey: self.currentUserId!) { isDriver in
                if isDriver == true {
                    self.removeOverlaysAndAnnotations(forDrivers: false, forPassegers: true)
                } else {
                    self.cancelBton.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                    self.actionBtton.animateButton(shouldLoad: false, withMessage: "REQUEST RIDE")
                    
                    self.destinationTextField.isUserInteractionEnabled = true
                    self.destinationTextField.text = ""
                    
                    self.removeOverlaysAndAnnotations(forDrivers: false, forPassegers: true)
                    self.centerMapOnUserLocation()
                }
            }
        }
        
        connectUserAndDriverForTrip()
    }
    
    
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
    
    func loadDriverAnnotationsFromFB(){
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value) { snapshot in
            if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for driver in driverSnapshot{
                    if driver.hasChild("userIsDriver"){
                        if driver.hasChild("coordinate"){
                            if driver.childSnapshot(forPath: "isPickupModeEnabled").value as? Bool == true{
                                if let driverDic = driver.value as? [String: AnyObject] {
                                    let coordinateArray = driverDic["coordinate"] as! NSArray
                                    let driverCoordinate = CLLocationCoordinate2D(latitude: coordinateArray[0] as! CLLocationDegrees, longitude: coordinateArray[1] as! CLLocationDegrees)
                                    
                                    
                                    let annotation = DriverAnnotation(coordinate: driverCoordinate, withKey: driver.key)
                                    
                                    var driverIsVisible: Bool{
                                        return self.mapView.annotations.contains(where:{ (annotation) -> Bool in
                                            if let driverAnnotation = annotation as? DriverAnnotation{
                                                if driverAnnotation.key == driver.key{
                                                    driverAnnotation.update(annotationPosition: driverAnnotation, withCoordinate: driverCoordinate)
                                                    return true
                                                }
                                            }
                                            return false
                                        })
                                    }
                                    
                                    if !driverIsVisible{
                                        self.mapView.addAnnotation(annotation)
                                    }
                                   
                                }
                            } else {
                                for annotation in self.mapView.annotations{
                                    if annotation.isKind(of: DriverAnnotation.self){
                                        if let annotation = annotation as? DriverAnnotation{
                                            if annotation.key == driver.key{
                                                self.mapView.removeAnnotation(annotation)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                 
                }
            }
        }
    }
    
    func connectUserAndDriverForTrip() {
        // Verificar si el usuario actual es un conductor[cite: 1, 2]
        DataService.instance.userIsDriver(userKey: currentUserId!) { (status) in
            if status == false {
                // Escuchar cambios en la referencia del viaje del usuario[cite: 1, 2]
                DataService.instance.REF_TRIPS.child(self.currentUserId!).observe(.value, with: { (tripSnapshot) in
                    let tripDict = tripSnapshot.value as? Dictionary<String, AnyObject>
                    
                    // Comprobar si el viaje ha sido aceptado[cite: 1, 2]
                    if tripDict?["tripIsAccepted"] as? Bool == true {
                        // Limpiar las anotaciones y capas anteriores del mapa[cite: 1, 2]
                        self.removeOverlaysAndAnnotations(forDrivers: false, forPassegers: true)
                        
                        // Obtener la ID del conductor y coordenadas de recolección[cite: 1, 2]
                        let driverId = tripDict?["driverKey"] as! String
                        let pickupCoordinateArray = tripDict?["pickupCoordinate"] as! NSArray
                        let pickupCoordinate = CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees)
                        let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)
                        let pickupMapItem = MKMapItem(placemark: pickupPlacemark)
                        
                        // Obtener la información del conductor desde la base de datos[cite: 1, 2]
                        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (driverSnapshot) in
                            if let driverSnapshot = driverSnapshot.children.allObjects as? [DataSnapshot] {
                                for driver in driverSnapshot {
                                    if driver.key == driverId {
                                        // Obtener las coordenadas del conductor[cite: 1, 2]
                                        let driverCoordinateArray = driver.childSnapshot(forPath: "coordinate").value as! NSArray
                                        let driverCoordinate = CLLocationCoordinate2D(latitude: driverCoordinateArray[0] as! CLLocationDegrees, longitude: driverCoordinateArray[1] as! CLLocationDegrees)
                                        let driverPlacemark = MKPlacemark(coordinate: driverCoordinate)
                                        let driverMapItem = MKMapItem(placemark: driverPlacemark)
                                        
                                        // Crear las anotaciones (pines) para el pasajero y el conductor[cite: 2]
                                        let passengerAnnotation = PassengerAnnotation(coordinate: pickupCoordinate, key: self.currentUserId!)
//                                        let driverAnnotation = DriverAnnotation(coordinate: driverCoordinate, withKey: driverId)
                                        
                                        // Agregar anotaciones y trazar la ruta en el mapa[cite: 2]
                                        self.mapView.addAnnotation(passengerAnnotation)
                                        self.searchMapKitForResultsWithPolyline(forOriginMapItem: driverMapItem, withDestinationMapItem: pickupMapItem)
                                        
                                        // Actualizar el estado del botón a "DRIVER COMING"[cite: 2]
                                        self.actionBtton.animateButton(shouldLoad: false, withMessage: "DRIVER COMING")
                                        self.actionBtton.isUserInteractionEnabled = false
                                    }
                                }
                            }
                        })
                    }
                })
            }
        }
    }
    
    func centerMapOnUserLocation(){
        let coordinateRegion = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    
    
    @IBAction func cancelBtonWasPressed(_ sender: Any) {
        DataService.instance.driverIsOnTrip(driverKey: currentUserId!) { isOnTrip, driverKey, tripKey in
            if isOnTrip == true{
                UpdateService.instance.cancelTrip(withPassengerKey: tripKey!, forDriverKey: driverKey!)
            }
        }
        
        DataService.instance.passengerIsOnTrip(passengerKey: currentUserId!) { isOnTrip, driverKey, tripKey in
            if isOnTrip == true{
                UpdateService.instance.cancelTrip(withPassengerKey: self.currentUserId!, forDriverKey: driverKey!)
            } else {
                UpdateService.instance.cancelTrip(withPassengerKey: self.currentUserId!, forDriverKey: nil)
            }
        }
        
        self.actionBtton.isUserInteractionEnabled = true
            
    }
    
    @IBAction func centerMapBtonPressed(_ sender: Any) {
        DataService.instance.REF_USERS.observeSingleEvent(of: .value) { snapshot in
            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for user in userSnapshot{
                    if user.key == self.currentUserId!{
                        if user.hasChild("tripCoordinate"){
                            self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: false, withKey: nil)
                            self.centerMapBton.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                        } else {
                            self.centerMapOnUserLocation()
                            self.centerMapBton.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                        }
                    }
                }
            }
        }
        
        
    }
    
    @IBAction func actionButtonWasPressed(_ sender: Any) {
        UpdateService.instance.updateTripsWithCoordinateUponRequest()
        actionBtton.animateButton(shouldLoad: true, withMessage: nil)
        
        self.view.endEditing(true)
        destinationTextField.isUserInteractionEnabled = false
    }
    
    @IBAction func menuBtnWasPressed(_ sender: Any) {
        delegate?.toggleLeftPanel()
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
        DataService.instance.REF_USERS.child(currentUserId!).child("tripCoordinate").removeValue()
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
        
        shouldPresentLoadingView(true)
        //get coodinate
        let passengerCoordinate = manager?.location?.coordinate
        let passengerAnnotation = PassengerAnnotation(coordinate: passengerCoordinate!, key: currentUserId!)
        mapView.addAnnotation(passengerAnnotation)
        
        //same title of field destination
        destinationTextField.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
        
        //save to firebase 'tripCoordinate'
        let selectedMapItem = matchingItems[indexPath.row]
        DataService.instance.REF_USERS.child(currentUserId!).updateChildValues(["tripCoordinate": [selectedMapItem.placemark.coordinate.latitude, selectedMapItem.placemark.coordinate.longitude]])
        
        
        dropPinFor(placeMark: selectedMapItem.placemark)
        
        searchMapKitForResultsWithPolyline(forOriginMapItem: nil, withDestinationMapItem: selectedMapItem)
        
        animateTableView(shouldShow: false)
        print("selected")
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
        print("🔄 PERMISSION:", manager.authorizationStatus.rawValue)

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

        print("📍 UBICACIÓN RECIBIDA:")
        print("Lat:", location.coordinate.latitude)
        print("Lon:", location.coordinate.longitude)

        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: regionRadius * 2,
            longitudinalMeters: regionRadius * 2
        )

        mapView.setRegion(region, animated: true)

        manager.stopUpdatingLocation()
    }
}
extension HomeVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        UpdateService.instance.updateUserLocation(withCoordinate: userLocation.coordinate)
        UpdateService.instance.updateDriverLocation(withCoordinate: userLocation.coordinate)
        
        
        DataService.instance.userIsDriver(userKey: currentUserId!) { isDriver in
            if isDriver == true{
                DataService.instance.driverIsOnTrip(driverKey: self.currentUserId!) { isOnTrip, driverKey, tripKey in
                    if isOnTrip == true{
                        self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                    } else {
                        self.centerMapOnUserLocation()
                    }
                }
            } else {
                DataService.instance.passengerIsOnTrip(passengerKey: self.currentUserId!) { isOnTrip, driverKey, tripKey in
                    if isOnTrip == true{
                        self.centerMapOnUserLocation()
                    }
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
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: any MKOverlay) -> MKOverlayRenderer {
        let linearRenderer = MKPolylineRenderer(overlay: self.route.polyline)
        linearRenderer.strokeColor = UIColor(red: 216/255, green: 71/255, blue: 30/255, alpha: 0.75)
        linearRenderer.lineWidth = 3
        
        shouldPresentLoadingView(false)
        
        self.zoom(toFitAnnotationsFromMapView: self.mapView,forActiveTripWithDriver: false, withKey: nil )
        
        return linearRenderer
    }
    
    func performSearch(){
        matchingItems.removeAll()
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = destinationTextField.text
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        
        search.start { response, error in
            if error != nil {
                self.showAlert("An error ocurred, please search something real")
            } else if response!.mapItems.count == 0 {
                self.showAlert("No result! Please search again..")
            } else {
                for mapItem in response!.mapItems {
                    self.matchingItems.append(mapItem as MKMapItem)
                    self.tableView.reloadData()
                    self.shouldPresentLoadingView(false)
                }
            }
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
        
        directions.calculate { response, error in
            guard let response = response else {
                self.showAlert(error as! String)
                return
            }
            
            
            self.route = response.routes[0] //the first route more faster
            //the line
            
         
            self.mapView.addOverlay(self.route.polyline)
            
            
            let delegate = AppDelegate.getAppDelegate()
            delegate.window?.rootViewController?.shouldPresentLoadingView(false)
            
        }
    }
    
    /// Ajusta el zoom del mapa para que se vean todas las anotaciones
    /// (excepto las de conductores) dentro de la pantalla.
    func zoom(toFitAnnotationsFromMapView mapView: MKMapView, forActiveTripWithDriver: Bool, withKey key: String?) {
        // Si no hay anotaciones no hay nada que encuadrar
        if mapView.annotations.count == 0 {
            return
        }

        // Empezamos con valores "imposibles" para que cualquier coordenada real los reemplace.
        // topLeft = esquina noroeste, bottomRight = esquina sureste
        var topLeftCoordinate = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        
        if forActiveTripWithDriver{
            for annotation in mapView.annotations{
                
                if let annotation =  annotation as? DriverAnnotation{
                    if annotation.key == key {
                        topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)         // más al oeste
                        topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)            // más al norte
                        bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude) // más al este
                        bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                    }
                } else {
                    topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)         // más al oeste
                    topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)            // más al norte
                    bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude) // más al este
                    bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                }
            }
        }

        // Recorremos las anotaciones, ignorando las de tipo DriverAnnotation,
        // para encontrar los extremos del rectángulo que las contiene a todas
        for annotation in mapView.annotations where !annotation.isKind(of: DriverAnnotation.self) {
            topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)         // más al oeste
            topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)            // más al norte
            bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude) // más al este
            bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)    // más al sur
        }

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
            
            if forPassegers!{
                if let annotation = annotation as? PassengerAnnotation{
                    mapView.removeAnnotation(annotation)
                }
            }
            if forDrivers!{
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
}



