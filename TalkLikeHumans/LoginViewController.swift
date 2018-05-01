//
//  LoginViewController.swift
//  TalkLikeHumans
//
//  Created by ppp on 8/11/16.
//  Copyright © 2016 Roy Emerson. All rights reserved.
//

import UIKit
import SVProgressHUD
import Alamofire

class LoginViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate, EPPickerDelegate{
    


    @IBOutlet weak var signInButton : GIDSignInButton!
    
    
    //---------------CALL TEST START-------------------
    /*
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        
        //Make a call
        //var callManager: SpeakerboxCallManager?
        //callManager = AppDelegate.shared.callManager
        //callManager?.startCall(handle: "123456789", video: false)
        
        //Receiving Call
        let backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now()) {
            AppDelegate.shared.displayIncomingCall(uuid: UUID(), handle: "987654321", hasVideo: false) { _ in
                UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            }
        }

    }
 */
    
    //---------------CALL TEST END-------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Set set the delegation
        GIDSignIn.sharedInstance().uiDelegate = self;
        GIDSignIn.sharedInstance().delegate = self;
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        //Check if the google token
        if GIDSignIn.sharedInstance().hasAuthInKeychain() {
            
            //GoTo the contact list screen
            self.goToContactListScreen()
            
        }
        else{
            self.setupGoogleLoginBtn()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = true
        AppData.sharedInstance.reportScreenNameToGAI("Login Screen");
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - UI setup for google login button
    func setupGoogleLoginBtn(){
        //Customize the button
        self.signInButton.style = GIDSignInButtonStyle.wide;
        self.signInButton!.colorScheme = GIDSignInButtonColorScheme.dark;
        
        //Revoke the previous authorization
//        GIDSignIn.sharedInstance().disconnect()
        
        // Uncomment to automatically sign in the user.
//        GIDSignIn.sharedInstance().signInSilently()
    }
    
    
    //MARK: -  User Interaction
    
    @IBAction func didTapSignIn(_ sender : UIButton) {
        SVProgressHUD.show()
    }
    
    @IBAction func didTapSignOut(_ sender : UIButton) {
        GIDSignIn.sharedInstance().signOut()
    }
    
    func goToContactListScreen() {
        
        AppData.sharedInstance.phone.login(startConnect: false)
        
        let contactPickerScene = EPContactsPicker(delegate: self, multiSelection:false, subtitleCellType: SubtitleCellValue.phoneNumber)
        self.navigationController?.pushViewController(contactPickerScene, animated: true)
        
    }
    
    //MARK: EPContactsPicker delegates
    func epContactPicker(_: EPContactsPicker, didContactFetchFailed error : NSError)
    {
        print("Failed with error \(error.description)")
    }
    
    func epContactPicker(_: EPContactsPicker, didSelectContact contact : EPContact)
    {
        print("Contact \(contact.displayName()) has been selected")
        
        let contactVC = Constants.storyBoard.instantiateViewController(withIdentifier: "ContactViewController") as! ContactViewController
        contactVC.contactInfo = contact
        self.navigationController?.pushViewController(contactVC, animated: true)
    }
    
    func epContactPicker(_: EPContactsPicker, didCancel error : NSError)
    {
        print("User canceled the selection");
    }
    
    func epContactPicker(_: EPContactsPicker, didSelectMultipleContacts contacts: [EPContact]) {
        print("The following contacts are selected")
        for contact in contacts {
            print("\(contact.displayName())")
        }
    }

    //MARK: - Web Service Call
    func storeGoogleToken(_ GOOToken : String) {
        AppData.sharedInstance.setUserGOOToken(GOOToken)
    }
    
    //MARK: - Web Service Call
    func getCapabilityToken() {
        //Show the loading bar
        SVProgressHUD.show()
        
        let deviceId = AppData.sharedInstance.getDeviceUniqueID()
        let deviceType = AppData.sharedInstance.getDeviceType()
        
        TLHAPI.getCapabiltyToken(deviceId, deviceType: deviceType) { (isSuccess : Bool, response : Any) in
            //Hide the loading bar
            SVProgressHUD.dismiss()
            
            if isSuccess{  //If success
                //Store the Capability Token
                let dictionary : Dictionary = response as! Dictionary<String,AnyObject>
                AppData.sharedInstance.setUserCapabilityToken(dictionary["access_token"] as! String)
                AppData.sharedInstance.setTwilioClientID(dictionary["deviceName"] as! String)
                
                //GoTo the contact list screen
                self.goToContactListScreen()
            }
            else{  // Fail
                AppData.showGenericAlert("Error", message: "Fetching the capability token is failed.")
            }
        }
        
    }
    
    
    //MARK: - Google Sign In Delegate
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        SVProgressHUD.dismiss()
        
        if error != nil{
            SVProgressHUD.dismiss()
            AppData.showGenericAlert("Error", message: "Authorizing Google Login is failed : \(error).")
            return;
        }
        
        print(user.profile.email)
        print(user.profile.imageURL(withDimension: 400))
        print("---------Successfully login--------")
        
        //Save the user information to local storage
        AppData.sharedInstance.setFirstName(user.profile.givenName)
        AppData.sharedInstance.setLastName(user.profile.familyName)
        
        //Store the Google Token
        self.storeGoogleToken(user.authentication.accessToken)
        
        //GoTo the contact list screen
        self.goToContactListScreen()
        
        //Call the API to get the capability token
//        self.getCapabilityToken()
    }
    
    // pressed the Sign In button
    func sign(inWillDispatch signIn: GIDSignIn!, error: Error!) {
        SVProgressHUD.show()
    }
    
    // Present a view that prompts the user to sign in with Google
    func sign(_ signIn: GIDSignIn!,
                present viewController: UIViewController!) {
        SVProgressHUD.dismiss()
        self.present(viewController, animated:true, completion: nil)
    }
    
    // Dismiss the "Sign in with Google" view
    func sign(_ signIn: GIDSignIn!,
                dismiss viewController: UIViewController!) {
        SVProgressHUD.show()
        self.dismiss(animated: true, completion: nil)
    }

}

