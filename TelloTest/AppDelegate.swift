//
//  AppDelegate.swift
//  TelloTest
//
//  Created by matsumoto keiji on 2018/05/02.
//  Copyright © 2018年 keiziweb. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
	}

	//DidEnterBackground
	func applicationDidEnterBackground(_ application: UIApplication) {
		let viewController:ViewController = self.window!.rootViewController as! ViewController
		viewController.closeConnection()
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
	}

	//DidBecomeActive
	func applicationDidBecomeActive(_ application: UIApplication) {
		let viewController:ViewController = self.window!.rootViewController as! ViewController
		viewController.connect()
	}

	//Terminate
	func applicationWillTerminate(_ application: UIApplication) {
	}


}

