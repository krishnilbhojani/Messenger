//
//  SceneDelegate.swift
//  Messenger
//
//  Created by Krishnil Bhojani on 24/04/20.
//  Copyright © 2020 Krishnil Bhojani. All rights reserved.
//

import UIKit
import Firebase

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        if let windowScene = scene as? UIWindowScene{
            let window = UIWindow(windowScene: windowScene)
            
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            
            let tutorialScreenViewController = TutorialScreenViewController(collectionViewLayout: layout)
            let messagesController = MessagesController()
            
            var navigationController = UINavigationController()
            
            if Auth.auth().currentUser?.uid != nil{
                navigationController = UINavigationController(rootViewController: messagesController)
                navigationController.navigationBar.isHidden = false
            }else{
                navigationController = UINavigationController(rootViewController: tutorialScreenViewController)
                navigationController.navigationBar.isHidden = true
            }
            
            window.rootViewController = navigationController
            window.makeKeyAndVisible()
            
            self.window = window
        }
        
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        
    }

    func sceneWillResignActive(_ scene: UIScene) {
        
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        
    }


}

