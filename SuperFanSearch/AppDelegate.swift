//
//  AppDelegate.swift
//  SchoolSearch
//
//  Created by Frederick Cowgill on 9/3/19.
//  Copyright © 2019 Frederick Cowgill. All rights reserved.
//

import UIKit

// 2026 update: `@UIApplicationMain` became `@main` (the old attribute is
// deprecated in current Swift).
@main
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // BUG FIX (2026): the old code force-unwrapped (`!` / `as!`) the window and
        // split view. If anything about the storyboard changed, the app crashed on
        // launch. Now it checks safely - an app that launches is an app-y app.
        guard let splitViewController = window?.rootViewController as? UISplitViewController,
              let navigationController = splitViewController.viewControllers.last as? UINavigationController else {
            return true
        }
        navigationController.topViewController?.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self
        return true
    }

    // MARK: - Split view

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
        if topAsDetailController.detailSchool == nil {
            // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
            return true
        }
        return false
    }

}
