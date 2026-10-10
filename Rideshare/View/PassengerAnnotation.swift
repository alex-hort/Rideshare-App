//
//  PassengerAnnotation.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 10/10/26.
//

import Foundation
import MapKit


class PassengerAnnotation: NSObject, MKAnnotation{
    dynamic var coordinate: CLLocationCoordinate2D
    var key: String
    
    init(coordinate: CLLocationCoordinate2D, key: String) {
        self.coordinate = coordinate
        self.key = key
        super.init()
    }
}
