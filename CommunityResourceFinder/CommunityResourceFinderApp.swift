//
//  CommunityResourceFinderApp.swift
//  CommunityResourceFinder
//
//  Created by Deke Bowman on 8/9/24.
//

import SwiftUI
import UIKit
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure Firebase first
        FirebaseApp.configure()
        
        // Then configure App Check with the right provider for the environment
        #if DEBUG
        // Use debug provider for simulator and development
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        #else
        // Use DeviceCheck provider for release builds
        let providerFactory = DeviceCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        #endif
        
        return true
    }
}


@main
struct ResourceFinderApp: App {
    // Register the AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Remove Firebase configuration from init since it's now in AppDelegate
    init() {
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
