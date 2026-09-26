//
//  UIView+Extensions.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 26/09/26.
//


import UIKit


extension UIView{
    
    // Registra el observador para escuchar cuando el teclado va a cambiar de tamaño/posición
    func bindToKeyboard() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, // ya es NSNotification.Name, no hace falta anidarlo
            object: nil
        )
    }

    // Se ejecuta cada vez que el teclado va a aparecer, desaparecer o cambiar de tamaño
    @objc func keyboardWillChange(_ notification: NSNotification) {
        
        // Duración de la animación del teclado (para que la nuestra combine con la del sistema)
        let duration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        // Curva de animación que usa el sistema (ease in/out, linear, etc.) como valor crudo
        let curve = notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! UInt
        // Frame del teclado ANTES del cambio (posición actual)
        let curFrame = (notification.userInfo![UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        // Frame del teclado DESPUÉS del cambio (posición final)
        let targetFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        // Diferencia vertical entre la posición final e inicial del teclado
        // (positivo si el teclado baja/se oculta, negativo si sube/aparece)
        let deltaY = targetFrame.origin.y - curFrame.origin.y
        // Anima el movimiento de la vista para que suba/baje junto con el teclado
        UIView.animateKeyframes(
            withDuration: duration,       // misma duración que la animación del teclado
            delay: 0.0,
            options: UIView.KeyframeAnimationOptions(rawValue: curve), // misma curva que usa el sistema
            animations: {
                // Mueve la vista completa sumando el desplazamiento del teclado
                self.frame.origin.y += deltaY
            },
            completion: nil
        )
    }
}
