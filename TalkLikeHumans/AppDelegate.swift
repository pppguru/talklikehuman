//
//  AppDelegate.swift
//  TalkLikeHumans
//
//  Created by ppp on 8/11/16.
//  Copyright © 2016 Roy Emerson. All rights reserved.
//

import UIKit
import UserNotifications
import PushKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PKPushRegistryDelegate{
    class var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    var window: UIWindow?
    let pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
    let callManager = SpeakerboxCallManager()
    var providerDelegate: ProviderDelegate?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool{
        //CallKit
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
        providerDelegate = ProviderDelegate(callManager: callManager)
        
        
        // Initialize Google sign-in
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        //Register Google Sign-in
//        GIDSignIn.sharedInstance().delegate = self
        
        // Optional: configure GAI options.
        let gai : GAI = GAI.sharedInstance()
        gai.trackUncaughtExceptions = false;  // report uncaught exceptions
        gai.logger.logLevel = GAILogLevel.verbose;  // remove before app release
        GAI.sharedInstance().logger.logLevel = GAILogLevel.none
        
        //Open the Splash
        self.openSplash()
        window?.makeKeyAndVisible()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let handle = url.startCallHandle else {
            print("Could not determine start call handle from URL: \(url)")
            
            return GIDSignIn.sharedInstance().handle(url,
                                                     sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                     annotation: options[UIApplicationOpenURLOptionsKey.annotation])
            //return false
        }
        
        AppData.sharedInstance.phone.startNewCall(phoneNumber: handle)
//        callManager.startCall(handle: handle)
        
        
        
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard let handle = userActivity.startCallHandle else {
            print("Could not determine start call handle from user activity: \(userActivity)")
            return false
        }
        
//        guard let video = userActivity.video else {
//            print("Could not determine video from user activity: \(userActivity)")
//            return false
//        }
//        
        AppData.sharedInstance.phone.startNewCall(phoneNumber: handle)
//        callManager.startCall(handle: handle, video: video)
        return true
    }
    
    // MARK: PKPushRegistryDelegate
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, forType type: PKPushType) {
        /*
         Store push credentials on server for the active user.
         For sample app purposes, do nothing since everything is being done locally.
         */
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, forType type: PKPushType) {
        guard type == .voIP else { return }
        
        if let uuidString = payload.dictionaryPayload["UUID"] as? String,
            let handle = payload.dictionaryPayload["handle"] as? String,
            let hasVideo = payload.dictionaryPayload["hasVideo"] as? Bool,
            let uuid = UUID(uuidString: uuidString)
        {
            displayIncomingCall(uuid: uuid, handle: handle, hasVideo: hasVideo)
        }
    }
    
    /// Display the incoming call to the user
    func displayIncomingCall(uuid: UUID, handle: String, hasVideo: Bool = false, completion: ((NSError?) -> Void)? = nil) {
        providerDelegate?.reportIncomingCall(uuid: uuid, handle: handle, hasVideo: hasVideo, completion: completion)
    }
    
    //MARK: - Splash
    func openSplash(){
        let firstNav = window?.rootViewController as! UINavigationController
        let splashVC = Constants.storyBoard.instantiateViewController(withIdentifier: "SplashVC")
        firstNav.pushViewController(splashVC as! SplashViewController, animated: false)
    }
    
    //MARK: - Logout
    func logout(){
        //Clear Google Token
        AppData.sharedInstance.setUserGOOToken("")
        //Clear JWT token
        AppData.sharedInstance.setUserCapabilityToken("")
        AppData.sharedInstance.setTwilioClientID("")
        //Disconnect from google
        GIDSignIn.sharedInstance().signOut()
        GIDSignIn.sharedInstance().disconnect()
        
        
        let firstNav = window?.rootViewController as! UINavigationController
        firstNav.popToRootViewController(animated: true);
    }

}

