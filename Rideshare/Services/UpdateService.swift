//
//  UpdateService.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 03/10/26.
//

import UIKit
import MapKit
import Firebase
import FirebaseAuth


class UpdateService {
    
    static var instance = UpdateService()
    
    func updateUserLocation(withCoordinate coordinate: CLLocationCoordinate2D){
        DataService.instance.REF_USERS.observeSingleEvent(of: .value) { snapshot in
            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for user in userSnapshot{
                    if user.key == Auth.auth().currentUser?.uid{
                        DataService.instance.REF_USERS.child(user.key).updateChildValues(["coordinate": [coordinate.latitude, coordinate.longitude]])
                    }
                }
            }
        }
    }
    
    func updateDriverLocation(withCoordinate coordinate: CLLocationCoordinate2D){
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value) { snapshot in
            if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for driver in driverSnapshot{
                    if driver.key == Auth.auth().currentUser?.uid{
                        if driver.childSnapshot(forPath: "isPickupModeEnabled").value as? Bool == true {
                            DataService.instance.REF_DRIVERS.child(driver.key).updateChildValues(["coordinate": [coordinate.latitude, coordinate.longitude]])
                        }
                    }
                }
            }
        }
    }
    
    // Escucha en tiempo real todos los viajes (trips) y le entrega al handler
    // el diccionario de cada viaje que sea una solicitud válida.
    func observeTrips(handler: @escaping (_ coordinateDict: [String: Any]?) -> Void) {
        // Se suscribe a REF_TRIPS: el closure se ejecuta cada vez que algo cambia en esa rama
        DataService.instance.REF_TRIPS.observe(.value) { snapshot in
            // Convierte los hijos del snapshot en un arreglo de DataSnapshot (un snapshot por viaje)
            guard let tripSnapshots = snapshot.children.allObjects as? [DataSnapshot] else { return }

            for trip in tripSnapshots {
                // Solo considera viajes que ya tengan pasajero y estado de aceptación,
                // es decir, solicitudes completas (ignora nodos a medio crear)
                if trip.hasChild("passengerKey") && trip.hasChild("tripIsAccepted") {
                    // Convierte el viaje a diccionario y se lo manda al handler
                    if let tripDict = trip.value as? [String: Any] {
                        handler(tripDict)
                    }
                }
            }
        }
    }
    
    
    func updateTripsWithCoordinateUponRequest() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        DataService.instance.REF_USERS.child(uid).observeSingleEvent(of: .value) { snapshot in
            guard !snapshot.hasChild("userIsDriver"),
                  let userDict = snapshot.value as? [String: Any],
                  let pickUpArray = userDict["coordinate"] as? [Double],
                  pickUpArray.count >= 2 else { return }

            DataService.instance.REF_TRIPS.child(uid).updateChildValues([
                "pickupCoordinate": [pickUpArray[0], pickUpArray[1]],
                "passengerKey": uid,
                "tripIsAccepted": false
            ])
        }
    }
    
    
    func acceptTrip(withPassengerKey passengerKey: String, forDriverKey driverKey: String){
        DataService.instance.REF_TRIPS.child(passengerKey).updateChildValues(["driverKey": driverKey, "tripIsAccepted": true])
        DataService.instance.REF_DRIVERS.child(driverKey).updateChildValues(["driverIsOnTrip": true])
    }
    
    func cancelTrip(withPassengerKey passengerKey: String, forDriverKey driverKey: String){
        DataService.instance.REF_TRIPS.child(passengerKey).removeValue()
        DataService.instance.REF_USERS.child(passengerKey).child("tripCoordinate").removeValue()
        DataService.instance.REF_DRIVERS.child(driverKey).updateChildValues(["driverIsOnTrip": false])
    }
    
}
