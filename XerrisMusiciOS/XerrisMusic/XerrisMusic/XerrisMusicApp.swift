//
//  XerrisMusicApp.swift
//  XerrisMusic
//
//  Created by Jason Wiker on 2020-12-26.
//
import Amplify
import AmplifyPlugins
import SwiftUI

// no changes in your AppDelegate class
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        do {
             try Amplify.add(plugin: AWSCognitoAuthPlugin())
             try Amplify.add(plugin: AWSPinpointAnalyticsPlugin())
             try Amplify.configure()
             print("Amplify configured with Auth and Analytics plugins")
         } catch {
             print("Failed to initialize Amplify with \(error)")
         }
        return true
    }
}

@main
struct XerrisMusicApp: App {
    
    // inject into SwiftUI life-cycle via adaptor !!!
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
