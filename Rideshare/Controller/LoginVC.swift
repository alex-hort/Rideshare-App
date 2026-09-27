//
//  LoginVC.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 26/09/26.
//

import UIKit
import FirebaseAuth

class LoginVC: UIViewController, UITextFieldDelegate {
    
    //MARK: BUTTONS EMAIL & PASSWORD
    
    @IBOutlet weak var emailField: RoundedCornerTextField!
    @IBOutlet weak var passwordField: RoundedCornerTextField!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var authBtton: RoundedShadowButton!
    
    
    override func viewDidLoad() {
        emailField.delegate = self
        passwordField.delegate = self
        
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
    

    @IBAction func authBtonWasPressed(_ sender: Any) {
        
        // Verifica que los campos tengan información
        if emailField.text != nil && passwordField.text != nil {
            
            // Muestra la animación de carga
            authBtton.animateButton(shouldLoad: true, withMessage: nil)
            
            // Oculta el teclado
            self.view.endEditing(true)
        }
        
        // Obtiene email y contraseña
        if let email = emailField.text,
           let password = passwordField.text {
            
            // Intenta iniciar sesión
            Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
                
                // Si el inicio de sesión fue exitoso
                if error == nil {
                    
                    if let result = result {
                        
                        // Si es usuario
                        if self.segmentedControl.selectedSegmentIndex == 0 {
                            
                            let userData = [
                                "provider": result.user.providerID
                            ] as [String: Any]
                            
                            // Guarda el usuario
                            DataService.instance.createFirebaseDBUser(
                                uid: result.user.uid,
                                userData: userData,
                                isDriver: false
                            )
                            
                        } else {
                            
                            // Datos del conductor
                            let userData = [
                                "provider": result.user.providerID,
                                "userIsDriver": true,
                                "isPickupModeEnable": false,
                                "driverIsOnTrip": false
                            ] as [String: Any]
                            
                            // Guarda el conductor
                            DataService.instance.createFirebaseDBUser(
                                uid: result.user.uid,
                                userData: userData,
                                isDriver: true
                            )
                        }
                    }
                    
                    // Login correcto
                    print("EMAIL USER AUTHENTICATED SUCCESSFULLY WITH FB")
                    
                    // Cierra la pantalla
                    self.dismiss(animated: true, completion: nil)
                    
                } else {
                    if let errorCode = AuthErrorCode(rawValue: error!._code) {
                        switch errorCode {
                        
                        case .wrongPassword:
                            print("Whoops! That was the wrong password!")
                        default:
                            print("An unexpected error occurred. Please try again.")
                        }
                    }
                    // Si el usuario no existe, intenta crearlo
                    Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
                        
                        // Si ocurrió un error
                        if let error = error {
                            // Obtiene el código del error
                            if let errorCode = AuthErrorCode(rawValue: error._code) {
                                switch errorCode {
                                case .invalidEmail:
                                    print("That is an invalid email!. Please try again.")
                                    
                                default:
                                    print("An unexpected error occurred. Please try again.")
                                }
                            }
                            
                        } else {
                            // Usuario creado correctamente
                            if let user = user {
                                
                                // Si es usuario
                                if self.segmentedControl.selectedSegmentIndex == 0 {
                                    
                                    let userData = [
                                        "provider": user.user.providerID
                                    ] as [String: Any]
                                    
                                    // Guarda el usuario en Firebase
                                    DataService.instance.createFirebaseDBUser(
                                        uid: user.user.uid,
                                        userData: userData,
                                        isDriver: false
                                    )
                                    
                                } else {
                                    
                                    // Datos del conductor
                                    let userData = [
                                        "provider": user.user.providerID,
                                        "userIsDriver": true,
                                        "isPickupModeEnable": false,
                                        "driverIsOnTrip": false
                                    ] as [String: Any]
                                    
                                    // Guarda el conductor en Firebase
                                    DataService.instance.createFirebaseDBUser(
                                        uid: user.user.uid,
                                        userData: userData,
                                        isDriver: true
                                    )
                                }
                                
                                print("SUCCESSFULLY CREATED A NEW USER WITH FB")
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
}
