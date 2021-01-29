//
//  AppDelegate.swift
//  VideoCallTest
//
//  Created by vhviet on 15/12/2020.
//

import UIKit
import IQKeyboardManager
import SVProgressHUD

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        IQKeyboardManager.shared().isEnabled = true
        
        SVProgressHUD.setBackgroundColor(.clear)
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.setDefaultStyle(.light)
        
        let navi = UINavigationController(rootViewController: HomeViewController.create(storyBoardName: "Main"))
        navi.isNavigationBarHidden = true
        window?.rootViewController = navi
        return true
    }


}

