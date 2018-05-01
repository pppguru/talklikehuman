//
//  AppData.swift
//  TalkLikeHumans
//
//  Created by ppp on 8/11/16.
//  Copyright © 2016 Expert Dev. All rights reserved.
//

import Foundation
import ReachabilitySwift
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class AppData {
    
    //MARK: - Singleton Instance
    
    class var sharedInstance: AppData {
        struct Static {
            static let instance: AppData = AppData()
        }
        return Static.instance
    }
    
    //MARK: - Variables
    var phone                               : Phone!
    
    var userDefaults                        : UserDefaults
    var isLoggedIn                          : Bool = false
    
    
    //MARK: - Initializer
    init() {
        self.phone = Phone()
        
        userDefaults = UserDefaults.standard
        isLoggedIn = false;
    }
    
    //MARK: - Global references
    func username() -> String{
        return userDefaults.string(forKey: "username")!
    }
    
    func setUsername(_ username : String){
        userDefaults.set(username, forKey: "username")
        userDefaults.synchronize()
    }
    
    func getFullName() -> String{
        return (self.firstName() ?? "") + " " + (self.lastName() ?? "")
    }
    
    func firstName() -> String?{
        return userDefaults.string(forKey: "FirstName")
    }
    
    func setFirstName(_ firstname : String){
        userDefaults.set(firstname, forKey: "FirstName")
        userDefaults.synchronize()
    }
    
    func lastName() -> String?{
        return userDefaults.string(forKey: "LastName")
    }
    
    func setLastName(_ lastname : String){
        userDefaults.set(lastname, forKey: "LastName")
        userDefaults.synchronize()
    }
    
    func userGOOToken() -> String{
        return userDefaults.string(forKey: "GOOToken")!
    }
    
    func setUserGOOToken(_ token : String){
        userDefaults.set(token, forKey: "GOOToken")
        userDefaults.synchronize()
    }
    
    func userCapabilityToken() -> String?{
        return userDefaults.string(forKey: "CapabilityToken") ?? ""
    }
    
    func setUserCapabilityToken(_ token : String){
        userDefaults.set(token, forKey: "CapabilityToken")
        userDefaults.synchronize()
    }
    
    func twilioClientID() -> String?{
        return userDefaults.string(forKey: "twilioClientID") ?? ""
    }
    
    func setTwilioClientID(_ token : String){
        userDefaults.set(token, forKey: "twilioClientID")
        userDefaults.synchronize()
    }
    
    //MARK: - Device Unique Name
    func getDeviceUniqueID() -> String{
        return UIDevice.current.identifierForVendor!.uuidString
    }
    
    func getDeviceType() -> String{
        
        return UIDevice.current.modelName
    }
    
    //MARK: - Google Analytics to report screen name
    func reportScreenNameToGAI(_ screenName : String){
        let tracker = GAI.sharedInstance().defaultTracker
        tracker?.set(kGAIScreenName, value: screenName)
        
        let builder = GAIDictionaryBuilder.createScreenView()
        tracker?.send(builder?.build() as! [NSObject : AnyObject])
    }
    
    //MARK: - Generic Alert
    /**
     A function that show the generic alert view
     @param
     @param
     @return
     */
    
    class func showGenericAlert(_ title : String, message : String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
            rootVC.present(alert, animated: true, completion: nil)
        }
    }

    
    //MARK: - TextField Check (Class Methods)
    class func isFieldEmpty(_ field : UITextField) -> Bool{
        if field.text?.characters.count > 0 {
            return false;
        }
        else{
            return true;
        }
    }
    
    class func isFieldEmail(_ field : UITextField) -> Bool{
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: field.text)
    }
    
    
    //MARK: - API Networking
    
    func apiKey() -> String{
        return Constants.APIKit.API_KEY
    }
    
    func getBaseURL() -> String{
        if Constants.APIKit.DEVEL_SERVER{
            return Constants.APIKit.BASEURL_DEVEL
        }
        else{
            return Constants.APIKit.BASEURL_PROD
        }
    }
    
    func wifiAvaiable() -> Bool{
        var reachability: Reachability?
        
        reachability = Reachability()// .reachabilityForInternetConnection()
        
        do{
            try reachability?.startNotifier()
        }catch{
            print("could not start reachability notifier")
            return false
        }
        
        if reachability!.isReachable {
            if reachability!.isReachableViaWiFi {
                print("Reachable via WiFi")
            } else {
                print("Reachable via Cellular")
            }
            
            return true
        } else {
            print("Network not reachable")
            return false
        }
    }
    
}
