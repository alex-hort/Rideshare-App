//
//  LeftSidePanelVC.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 19/09/26.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class LeftSidePanelVC: UIViewController {
    
    let appDelegate = AppDelegate.getAppDelegate()
    
    let currentUserId = Auth.auth().currentUser?.uid
    
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var userAccountLabel: UILabel!
    @IBOutlet weak var userImageView: RoundImageView!
    @IBOutlet weak var loginOutBtton: UIButton!
    @IBOutlet weak var pickupModeSwitch: UISwitch!
    @IBOutlet weak var pickupModeLabel: UILabel!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        pickupModeSwitch.isOn = false
        pickupModeSwitch.isHidden = true
        pickupModeLabel.isHidden = false
        
        observePassengerAndDrivers()
        
        
        if Auth.auth().currentUser == nil {
            userEmailLabel.text = ""
            userAccountLabel.text = ""
            userImageView.isHidden = true
            loginOutBtton.setTitle("Sign Up / Login", for: .normal)
        } else {
            userEmailLabel.text = Auth.auth().currentUser?.email
            userAccountLabel.text = ""
            userImageView.isHidden = false
            loginOutBtton.setTitle("Logout", for: .normal)
        }
    }
    
    func observePassengerAndDrivers(){
        DataService.instance.REF_USERS.observeSingleEvent(of: .value) { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for snap in snapshot{
                    if snap.key == Auth.auth().currentUser?.uid{
                        self.userAccountLabel.text = "PASSENGER"
                    }
                }
            }
        }
        
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value) { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for snap in snapshot {
                    if snap.key == Auth.auth().currentUser?.uid{
                        self.userAccountLabel.text = "DRIVER"
                        self.pickupModeSwitch.isHidden = false
                        
                        let switchStatus = snap.childSnapshot(forPath: "isPickupModeEnabled").value as! Bool
                        self.pickupModeSwitch.isOn = switchStatus
                        self.pickupModeLabel.isHidden = false
                    }
                }
            }
            
        
        }
    }
    
    

    @IBAction func signUpLoginBtnWasPressed(_ sender: Any) {
        if Auth.auth().currentUser == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginVC
            present(loginVC!, animated: true, completion: nil)
        } else {
            do{
                try Auth.auth().signOut()
                userEmailLabel.text = ""
                userAccountLabel.text = ""
                userImageView.isHidden = true
                pickupModeLabel.text = ""
                pickupModeSwitch.isHidden = true
                loginOutBtton.setTitle("Sign Up / Login", for: .normal)
            }catch(let error){
               print(error)
            }
        }
    }
    
    
    
    @IBAction func switchWasToggle(_ sender: Any) {
        if pickupModeSwitch.isOn{
            pickupModeLabel.text = "PICKUP MODE ENABLED"
            appDelegate.menuConteinerVC.toggleLeftPanel()
            DataService.instance.REF_DRIVERS.child(currentUserId!).updateChildValues(["isPickupModeEnabled": true])
        } else {
            pickupModeLabel.text = "PICKUP MODE DISABLED"
            appDelegate.menuConteinerVC.toggleLeftPanel()
            DataService.instance.REF_DRIVERS.child(currentUserId!).updateChildValues(["isPickupModeEnabled":false])
        }
    }
    
}
