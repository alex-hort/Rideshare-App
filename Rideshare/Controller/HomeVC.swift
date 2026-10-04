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


class HomeVC: UIViewController{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var actionBtton: RoundedShadowButton!
    @IBOutlet weak var centerMapBton: UIButton!
    @IBOutlet weak var destinationTextField: UITextField!
    @IBOutlet weak var destinationCircle: CircleView!
    
    var delegate: CenterVCDelegate?
    
    var manager: CLLocationManager?
    var regionRadius: CLLocationDistance = 1000
    
    let revealingSplashView =  RevealingSplashView(iconImage: .launchScreenIcon, iconInitialSize: CGSize(width: 80, height: 80), backgroundColor: .white)
    
    var tableView =  UITableView()
    
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
        }


        self.view.addSubview(revealingSplashView)
        revealingSplashView.animationType = SplashAnimationType.heartBeat
        revealingSplashView.startAnimation()
        revealingSplashView.heartAttack = true
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
    
    
    func centerMapOnUserLocation(){
        let coordinateRegion = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    @IBAction func centerMapBtonPressed(_ sender: Any) {
        centerMapOnUserLocation()
        centerMapBton.fadeTo(alphaValue: 0.0, withDuration: 0.2)
    }
    
    @IBAction func actionButtonWasPressed(_ sender: Any) {
        actionBtton.animateButton(shouldLoad: true, withMessage: nil)
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
            //performSearch()
            view.endEditing(true)
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
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
        return UITableViewCell()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        animateTableView(shouldShow: false)
        print("selected")
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
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation{
            let identifier = "driver"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage(named: "driverAnnotation")
            return view
        }
        return nil
    
    }
    
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        centerMapBton.fadeTo(alphaValue: 1.0, withDuration: 0.2)
    }
}



