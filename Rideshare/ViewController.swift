//
//  ViewController.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 13/09/26.
//

import UIKit
import MapKit

class ViewController: UIViewController, MKMapViewDelegate{

    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var actionBtton: RoundedShadowButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self 
       
    }

    @IBAction func actionButtonWasPressed(_ sender: Any) {
        actionBtton.animateButton(shouldLoad: true, withMessage: nil)
    }
    
}

