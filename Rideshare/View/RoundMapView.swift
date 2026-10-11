//
//  RoundMapView.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 11/10/26.
//

import UIKit
import MapKit

class RoundMapView: MKMapView {
    
    override func awakeFromNib() {
           super.awakeFromNib()
           layer.borderColor = UIColor.white.cgColor
           layer.borderWidth = 10.0
           clipsToBounds = true
       }

       override func layoutSubviews() {
           super.layoutSubviews()
           layer.cornerRadius = bounds.width / 2
       }
   

}
