//
//  PickupVC.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 11/10/26.
//

import UIKit
import MapKit
import FirebaseAuth
import Firebase



class PickupVC: UIViewController {
    
    
    @IBOutlet weak var pickupMapView: RoundMapView!
    
    var regionRadius: CLLocationDistance = 2000
    var pin: MKPlacemark? = nil
    var currentUserId = Auth.auth().currentUser?.uid
    
    var locationPlaceMark: MKPlacemark!
    
    var pickupCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var passengerKey: String!
    
  
    override func viewDidLoad() {
        super.viewDidLoad()

        pickupMapView.delegate = self
        
        locationPlaceMark = MKPlacemark(coordinate: pickupCoordinate)
        
        dropPinFor(placemark: locationPlaceMark)
        centerMapOnLocation(location: locationPlaceMark.location!)
        
        DataService.instance.REF_TRIPS.child(passengerKey).observe(.value) { tripSnapshot in
        
            if tripSnapshot.exists(){
                //check for acceptance
                if tripSnapshot.childSnapshot(forPath: "tripIsAccepted").value as? Bool == true {
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                self.dismiss(animated: true, completion: nil)
            }
            
        }
        
    }
    
    func initData(coordinate: CLLocationCoordinate2D, passengerKey: String){
        self.pickupCoordinate = coordinate
        self.passengerKey = passengerKey
    }
    

    @IBAction func acceptTripBtnWasPressed(_ sender: Any) {
        UpdateService.instance.acceptTrip(withPassengerKey: passengerKey, forDriverKey: currentUserId!)
        presentedViewController?.shouldPresentLoadingView(true)
    }
    
    @IBAction func cancelBtonWasPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    

}


extension PickupVC: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, viewFor annotation: any MKAnnotation) -> MKAnnotationView? {
        let identifier = "pickupPoint"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        } else{
            annotationView?.annotation = annotation
        }
        annotationView?.image = UIImage(named: "destinationAnnotation")
        return annotationView
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: regionRadius,
            longitudinalMeters: regionRadius
        )
        pickupMapView.setRegion(coordinateRegion, animated: true)
    }

    func dropPinFor(placemark: MKPlacemark) {
        pin = placemark

        pickupMapView.removeAnnotations(pickupMapView.annotations)

        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate

        pickupMapView.addAnnotation(annotation)
    }
    
}
