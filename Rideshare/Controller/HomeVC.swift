//
//  ViewController.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 13/09/26.
//

import UIKit
import MapKit
import RevealingSplashView


class HomeVC: UIViewController, MKMapViewDelegate{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var actionBtton: RoundedShadowButton!
    
    var delegate: CenterVCDelegate?
    let revealingSplashView =  RevealingSplashView(iconImage: .launchScreenIcon, iconInitialSize: CGSize(width: 80, height: 80), backgroundColor: .white)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        //MARK: ANIMATION LAUNCHSCREEN SplashView
        self.view.addSubview(revealingSplashView)
        revealingSplashView.animationType = SplashAnimationType.heartBeat
        revealingSplashView.startAnimation()
        
        revealingSplashView.heartAttack = true
       
    }

    @IBAction func actionButtonWasPressed(_ sender: Any) {
        actionBtton.animateButton(shouldLoad: true, withMessage: nil)
    }
    
    @IBAction func menuBtnWasPressed(_ sender: Any) {
        delegate?.toggleLeftPanel()
    }
}

