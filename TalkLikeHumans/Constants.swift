//
//  Constants.swift
//  TalkLikeHumans
//
//  Created by ppp on 8/11/16.
//  Copyright © 2016 Roy Emerson. All rights reserved.
//

import Foundation
import UIKit


struct Constants {
    
    static var storyBoard = UIStoryboard(name : "Main", bundle: nil)
    
    struct APIKit {
        static let API_KEY       = ""
        static let BASEURL_PROD  = "http://wewantto.talklikehumans.com/api/v1"
        static let BASEURL_DEVEL = "http://wewantto.talklikehumans.com/api/v1"
        static let DEVEL_SERVER  = false
        
        static let LOGIN_ACTION     = "/login"
        static let REGISTER_ACTION  = "/register"
        static let STATUS_ACTION    = "/status"
        static let CAPABILITYTOKEN  = "/capabilitytoken"
    }
    
    struct TWILIO {
        static let TwilioTest_Key            = "pk_test_ds72MJJZR9yFjPEe95NRY0PF"
        static let TwilioPublishableKey      = "pk_live_Ogwq4JXmWnW0S341wnFRgzGE"
    }
}



