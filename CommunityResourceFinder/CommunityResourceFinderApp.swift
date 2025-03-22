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
//        FirebaseApp.configure()
//        
//        let db = Firestore.firestore()
//        let settings = db.settings
//        settings.cacheSettings = CacheSettings(persistenceEnabled: true)
        
        // Then configure App Check with the right provider for the environment
        #if DEBUG
        print("Using App Check Debug Provider")
        let debugToken = UserDefaults.standard.string(forKey: "AppCheckDebugToken") ?? UUID().uuidString
        UserDefaults.standard.set(debugToken, forKey: "AppCheckDeubgToken")
        print("App Check debug token: \(debugToken)")
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        #else
        print("Using DeviceCheckProvider")
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

    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
