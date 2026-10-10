//
//  UIViewController+Extensions.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 10/10/26.
//

import UIKit

extension UIViewController{
    
    func shouldPresentLoadingView(_ status: Bool) {
        if status {
            let fadeView = UIView(frame: view.bounds)
            fadeView.backgroundColor = .black
            fadeView.alpha = 0.0
            fadeView.tag = 99

            let spinner = UIActivityIndicatorView(style: .large)
            spinner.color = .white
            spinner.center = fadeView.center
            spinner.startAnimating()

            view.addSubview(fadeView)
            fadeView.addSubview(spinner)

            fadeView.fadeTo(alphaValue: 0.7, withDuration: 0.2)
        } else {
            for subview in view.subviews where subview.tag == 99 {
                UIView.animate(withDuration: 0.2, animations: {
                    subview.alpha = 0.0
                }, completion: { _ in
                    subview.removeFromSuperview()
                })
            }
        }
    }
}
