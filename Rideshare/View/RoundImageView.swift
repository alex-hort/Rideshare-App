//
//  RoundImageView.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 14/09/26.
//


import UIKit

class RoundImageView: UIImageView{
    
    
    override func awakeFromNib(){
        setupView()
    }
    
    func setupView(){
        self.layer.cornerRadius = self.frame.width / 2
        self.clipsToBounds = true
    }
}
