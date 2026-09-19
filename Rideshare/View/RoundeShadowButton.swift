//
//  RoundeShadowButton.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 14/09/26.
//

import UIKit

class RoundedShadowButton: UIButton {

    private var originalBackground: UIColor?
    private var originalShadowOpacity: Float = 0.3

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }

    func setupView() {
        originalBackground = self.backgroundColor
        self.layer.cornerRadius = 5.0
        self.layer.shadowRadius = 10.0
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowOpacity = originalShadowOpacity
        self.layer.shadowOffset = CGSize.zero
    }

    func animateButton(shouldLoad: Bool, withMessage message: String?) {
        if shouldLoad {
            let spinner = UIActivityIndicatorView(style: .large)
            spinner.color = .darkGray
            spinner.alpha = 0
            spinner.hidesWhenStopped = true
            spinner.tag = 21
            spinner.translatesAutoresizingMaskIntoConstraints = false

            addSubview(spinner)
            NSLayoutConstraint.activate([
                spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
                spinner.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])

            setTitle("", for: .normal)
            isUserInteractionEnabled = false
            spinner.startAnimating()

            UIView.animate(withDuration: 0.2) {
                self.backgroundColor = .clear
                self.layer.shadowOpacity = 0
                spinner.alpha = 1
            }
        } else {
            isUserInteractionEnabled = true
            subviews.filter { $0.tag == 21 }.forEach { $0.removeFromSuperview() }

            UIView.animate(withDuration: 0.2) {
                self.backgroundColor = self.originalBackground
                self.layer.shadowOpacity = self.originalShadowOpacity
            }
            setTitle(message, for: .normal)
        }
    }
}
