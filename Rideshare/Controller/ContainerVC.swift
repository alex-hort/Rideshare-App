//
//  ContainerVC.swift
//  Rideshare
//
//  Created by Alexis Horteales Espinosa on 19/09/26.
//

import UIKit
import QuartzCore

// Estados del menú lateral
enum SlideOutState {
    case collapsed              // Menú cerrado
    case leftPanelExpanded      // Menú abierto
}

// Pantalla que se mostrará
enum ShowWichVC {
    case homeVC
}

var showVC: ShowWichVC = .homeVC

class ContainerVC: UIViewController {

    // Pantalla principal
    var homeVC: HomeVC!

    // Guarda si el menú está cerrado o abierto
    var currentState: SlideOutState = .collapsed

    // Panel lateral
    var leftVC: LeftSidePanelVC!

    // Indica si el panel está oculto
    var isHidden = false

    // Cuánto se mueve la pantalla central al abrir el menú
    let centerPanelExpandOffset: CGFloat = 160

    // ViewController que actualmente se muestra en el centro
    var centerController: UIViewController!
    var tap: UITapGestureRecognizer!


    override func viewDidLoad() {
        super.viewDidLoad()
        initCenter(screen: showVC)
    }

    // Inicializa y muestra la pantalla central
    func initCenter(screen: ShowWichVC) {

        // ViewController que se va a mostrar
        var presentingController: UIViewController

        // Guarda qué pantalla se quiere mostrar
        showVC = screen

        // Si HomeVC todavía no existe, lo crea
        if homeVC == nil {
            homeVC = UIStoryboard.homeVC()

            // Permite que HomeVC se comunique con ContainerVC
            homeVC.delegate = self
        }

        // La pantalla que se mostrará será HomeVC
        presentingController = homeVC

        // Si ya había una pantalla central, la elimina
        if let con = centerController {
            con.view.removeFromSuperview()
            con.removeFromParent()
        }
        // Guarda la nueva pantalla central
        centerController = presentingController

        // Agrega su vista al Container
        view.addSubview(centerController.view)

        // Agrega el ViewController como hijo
        addChild(centerController)

        // Confirma que ya pertenece al Container
        centerController.didMove(toParent: self)
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        return UIStatusBarAnimation.slide
    }
    
    override var prefersStatusBarHidden: Bool{
        return isHidden
    }
}

// Controla las acciones del menú lateral
extension ContainerVC: CenterVCDelegate {
    
    // Abre o cierra el menú lateral
    func toggleLeftPanel() {
        // Verifica si el menú está cerrado
        let notAllreadyExpanded = (currentState != .leftPanelExpanded)
        // Si está cerrado, agrega el panel
        if notAllreadyExpanded {
            addLeftPanelViewController()
        }
        // Ejecuta la animación del panel
        animateLeftPanel(shouldExpand: notAllreadyExpanded)
    }
    // Agrega el panel lateral a la pantalla
    func addLeftPanelViewController() {
        // Solo lo crea si todavía no existe
        if leftVC == nil {
            leftVC = UIStoryboard.leftViewController()
            addChildPanelViewController(leftVC!)
        }
    }
    
    // Agrega el ViewController lateral como hijo del Container
    func addChildPanelViewController(_ sidePanelController: LeftSidePanelVC) {
        // Coloca la vista del panel detrás de la principal
        view.insertSubview(sidePanelController.view, at: 0)
        // Agrega el ViewController hijo
        addChild(sidePanelController)
        // Indica que ya forma parte del Container
        sidePanelController.didMove(toParent: self)
    }
    
    
    
    // Aquí se realiza la animación de abrir/cerrar el menú
    @objc func animateLeftPanel(shouldExpand: Bool) {
        if shouldExpand{
            isHidden = !isHidden
            animateStatusBar()
            //            setupWhiteCoverView()
            currentState = .leftPanelExpanded
            animateCenterPanelXPosition(targetPosition: centerController.view.frame.width - centerPanelExpandOffset)
        } else {
            isHidden = !isHidden
            animateStatusBar()
            //            hideWhiteCoverView()
            animateCenterPanelXPosition(targetPosition: 0) { (finished) in
                if finished == true {
                    self.currentState = .collapsed
                    self.leftVC = nil
                }
            }
        }
    }

    
    func animateCenterPanelXPosition(targetPosition: CGFloat, completion: ((Bool) -> Void)! = nil){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.centerController.view.frame.origin.x = targetPosition
        }, completion: completion)
    }
    
    func setupWhiteCoverView(){
        let whiteCoverView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        whiteCoverView.alpha = 0.0
        whiteCoverView.backgroundColor = UIColor.white
        whiteCoverView.tag = 25
        
        self.centerController.view.addSubview(whiteCoverView)
        UIView.animate(withDuration: 0.2) {
           
            whiteCoverView.alpha = 0.75
        }
        tap = UITapGestureRecognizer(target: self, action: #selector(animateLeftPanel(shouldExpand:)))
        tap.numberOfTapsRequired = 1
        
        self.centerController.view.addGestureRecognizer(tap)
    }
    
    func hideWhiteCoverView(){
        centerController.view.removeGestureRecognizer(tap)
        for subView in self.centerController.view.subviews{
            if subView.tag == 25{
                UIView.animate(withDuration: 0.2) {
                    subView.alpha = 0.0
                } completion: { (finished) in
                    subView.removeFromSuperview()
                }
            }
        }
    }
    
    func animateStatusBar(){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
}

// Extensión para obtener ViewControllers desde el Storyboard
private extension UIStoryboard {

    // Abre el Storyboard principal
    class func mainStoryboard() -> UIStoryboard {
        return UIStoryboard(name: "Main", bundle: Bundle.main)
    }

    // Obtiene el ViewController del menú lateral
    class func leftViewController() -> LeftSidePanelVC? {
        return mainStoryboard()
            .instantiateViewController(withIdentifier: "LeftSidePanelVC")
            as? LeftSidePanelVC
    }

    // Obtiene el ViewController principal
    class func homeVC() -> HomeVC? {
        return mainStoryboard()
            .instantiateViewController(withIdentifier: "HomeVC")
            as? HomeVC
    }
}

