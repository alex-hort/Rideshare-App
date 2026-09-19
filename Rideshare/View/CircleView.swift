//
//  CircleView.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 14/09/26.
//

import UIKit

class CircleView: UIView {

    @IBInspectable var borderColor: UIColor?{
        didSet{
            setupView()
        }
    }
    
    override func awakeFromNib() {
        setupView()
    }
    
    func setupView(){
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.borderWidth = 1.5
        self.layer.borderColor = borderColor?.cgColor
    }

}
