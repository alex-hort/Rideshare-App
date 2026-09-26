//
//  LoginVC.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 26/09/26.
//

import UIKit

class LoginVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.bindToKeyboard()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleScreenTap(sender:)))
        self.view.addGestureRecognizer(tap)
        
       


    }
    @objc func handleScreenTap(sender: UITapGestureRecognizer){
        self.view.endEditing(true)
    }

    @IBAction func cancelBttnWasPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}
