//
//  PickupVC.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 11/10/26.
//

import UIKit
import MapKit


class PickupVC: UIViewController {
    
    
    @IBOutlet weak var pickupMapView: RoundMapView!
    
    var regionRadius: CLLocationDistance = 2000
    var pin: MKPlacemark? = nil
    
    var locationPlaceMark: MKPlacemark!
    
    var pickupCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var passengerKey: String!
    
  
    override func viewDidLoad() {
        super.viewDidLoad()

        pickupMapView.delegate = self
        
        locationPlaceMark = MKPlacemark(coordinate: pickupCoordinate)
        
        dropPinFor(placemark: locationPlaceMark)
        centerMapOnLocation(location: locationPlaceMark.location!)
        
    }
    
    func initData(coordinate: CLLocationCoordinate2D, passengerKey: String){
        self.pickupCoordinate = coordinate
        self.passengerKey = passengerKey
    }
    

    @IBAction func acceptTripBtnWasPressed(_ sender: Any) {
        
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
