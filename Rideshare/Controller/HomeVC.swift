//
//  ViewController.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 13/09/26.
//

import UIKit
import MapKit

class HomeVC: UIViewController, MKMapViewDelegate{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var actionBtton: RoundedShadowButton!
    
    var delegate: CenterVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self 
       
    }

    @IBAction func actionButtonWasPressed(_ sender: Any) {
        actionBtton.animateButton(shouldLoad: true, withMessage: nil)
    }
    
    @IBAction func menuBtnWasPressed(_ sender: Any) {
        delegate?.toggleLeftPanel()
    }
}

