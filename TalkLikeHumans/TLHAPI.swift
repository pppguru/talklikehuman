//
//  TLHAPI.swift
//  TalkLikeHumans
//
//  Created by Expert Dev on 8/11/16.
//  Copyright © 2016. All rights reserved.
//

import Foundation
import Alamofire


class TLHAPI{
    
    //MARK: - API Calls
    // --------------------  Get Capability Token ---------------------
    class func getCapabiltyToken(_ deviceId : String, deviceType : String, completionHandler : @escaping ((Bool, Any) -> ())) {
        let errorHeader : String = "Error(API Call - Capability Token)"
        
        //check internet connection first
        if !TLHAPI.checkInternetConnection() {
            completionHandler(false, "Internet connection is lost!" as AnyObject);
            return
        }
        
        //check param nil
        if !TLHAPI.checkStringParamsNil(deviceId, deviceType) {
            completionHandler(false, "Param is not correctly set!" as AnyObject)
            return
        }
        
        var url = AppData.sharedInstance.getBaseURL()
        url = url + Constants.APIKit.CAPABILITYTOKEN
        url = url + "?deviceId=\(deviceId)"
        url = url + "&deviceType=\(deviceType)"
        url = url.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        
        let headers : Dictionary = ["Authorization" : "Bearer \(AppData.sharedInstance.userGOOToken())"]
        
        Alamofire.request(url, parameters: nil, encoding: URLEncoding.default, headers: headers)
                            .validate()
                                .responseJSON(completionHandler: { (response) in
                                    print(response.request)
                                    
                                    guard response.result.isSuccess else {
                                        completionHandler(false, "\(errorHeader) : \(response.result.error)" as AnyObject)
                                        return
                                    }
                                    
                                    print(response.result.value)
                                    completionHandler(true, response.result.value as AnyObject)

        })
    
    }
    
    //MARK: - Param Check
    
    /**
     A function that check if any param is nil
     @param1 the first param
     @param2 the second number
     ...
     @returns bool value for check result
     */
    
    class func checkStringParamsNil(_ args:String? ...) -> Bool{
        for arg : String? in args {
            if arg != nil && arg!.characters.count == 0 {
                return false
            }
        }
        return true
    }
    
    //MARK: - Internet Connection Check
    /**
     A function that check the internet connection
     @param
     @param
     @return
     */
    
    class func checkInternetConnection() -> Bool{
        if !AppData.sharedInstance.wifiAvaiable() {
            AppData.showGenericAlert("Error", message: "No internet connection! Please check your wifi or cell signal and try again.")
            return false;
        }
        
        return true;
    }

    
}
