//
//  RoundedCornerTextField.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 26/09/26.
//

import UIKit

// TextField personalizado con bordes redondeados
class RoundedCornerTextField: UITextField {
    
    // Espacio interno para el texto
    var textRectOffset: CGFloat = 20
    
    // Se ejecuta cuando el TextField se carga desde Storyboard/XIB
    override func awakeFromNib() {
        layoutSubviews()
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        clipsToBounds = true
    }
    
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: textRectOffset, dy: 0)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.insetBy(dx: textRectOffset, dy: 0)
    }
}
