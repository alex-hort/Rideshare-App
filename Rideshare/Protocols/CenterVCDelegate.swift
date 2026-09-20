//
//  CenterVCDelegate.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 19/09/26.
//

import UIKit

protocol CenterVCDelegate{
    func toggleLeftPanel()
    func addLeftPanelViewController()
    func animateLeftPanel(shouldExpand: Bool)
}


