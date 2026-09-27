//
//  DataService.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 27/09/26.
//

import Foundation
import Firebase

// Referencia principal a la base de datos de Firebase
let DB_BASE = Database.database().reference()

class DataService {
    
    // Crea una sola instancia de DataService (Singleton)
    static let instance = DataService()
    // Referencia principal de la base de datos
    private var _REF_BASE = DB_BASE
    // Referencia a la colección "users"
    private var _REF_USERS = DB_BASE.child("users")
    // Referencia a la colección "drivers"
    private var _REF_DRIVERS = DB_BASE.child("drivers")
    // Referencia a la colección "trips"
    private var _REF_TRIPS = DB_BASE.child("trips")
    // Permite acceder a la referencia principal
    var REF_BASE: DatabaseReference {
        return _REF_BASE
    }
    
    // Permite acceder a los usuarios
    var REF_USERS: DatabaseReference {
        return _REF_USERS
    }
    
    // Permite acceder a los conductores
    var REF_DRIVERS: DatabaseReference {
        return _REF_DRIVERS
    }
    
    // Permite acceder a los viajes
    var REF_TRIPS: DatabaseReference {
        return _REF_TRIPS
    }
    
    //MARK: FUNCIONES
    
    // Crea un usuario en Firebase
    func createFirebaseDBUser(
        uid: String,
        userData: [String: Any],
        isDriver: Bool
    ) {
        
        // Si es conductor, lo guarda en "drivers"
        if isDriver {
            REF_DRIVERS.child(uid).updateChildValues(userData)
            
        // Si no, lo guarda en "users"
        } else {
            REF_USERS.child(uid).updateChildValues(userData)
        }
    }
}
