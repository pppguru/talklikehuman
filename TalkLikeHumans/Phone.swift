//
//  Phone.swift
//  TalkLikeHumans
//
//  Created by ppp on 8/15/16.
//  Copyright © 2016 Expert Dev. All rights reserved.
//

import Foundation
import AVFoundation
import SVProgressHUD
import JCDialPad
import FontasticIcons

public class Phone : NSObject, TCDeviceDelegate, TCConnectionDelegate, JCDialPadDelegate {
    var device                              :TCDevice!
    var connection                          :TCConnection!
    var pendingConnection                   :TCConnection!

    var callPad                             : JCDialPad = JCDialPad.init()
    var receiveCall                         : JCDialPad = JCDialPad.init()
    var phoneNumberToCall                   : String = ""
    
    var callManager                         : SpeakerboxCallManager?
    let receivingIncomingCallNotification   = Notification.Name("PendingIncomingConnectionReceived")
    
    override init(){
        super.init();
        
        callManager = AppDelegate.shared.callManager
        
        NotificationCenter.default.addObserver(self, selector: #selector(Phone.pendingIncomingConnectionReceived), name: receivingIncomingCallNotification, object: nil)
        
    }
    
    func login(startConnect : Bool, params : Dictionary<String,String> = Dictionary<String,String>()) {
        
        let strCapabilityToken : String? = AppData.sharedInstance.userCapabilityToken()
        if strCapabilityToken == nil || strCapabilityToken?.characters.count == 0 {
            let deviceId = AppData.sharedInstance.getDeviceUniqueID()
            let deviceType = AppData.sharedInstance.getDeviceType()
            
            SVProgressHUD.show()
            
            TLHAPI.getCapabiltyToken(deviceId, deviceType: deviceType) { (isSuccess : Bool, response : Any) in
                //Hide the loading bar
                SVProgressHUD.dismiss()
                
                if isSuccess{  //If success
                    //Store the Capability Token
                    let dictionary : Dictionary = response as! Dictionary<String,AnyObject>
                    
                    let token = dictionary["access_token"] as! String
                    AppData.sharedInstance.setUserCapabilityToken(token)
                    
                    let deviceName = dictionary["deviceName"] as! String
                    AppData.sharedInstance.setTwilioClientID(deviceName)
                    
                    
                    if self.device == nil {
                        self.device = TCDevice(capabilityToken: token, delegate: self)
                    }
                    else {
                        self.device!.updateCapabilityToken(token)
                    }
                    
                    
                    //If startConnect is true, start connect!
                    if startConnect == true {
                        self.connectWithParams(params: params)
                    }
                    
                }
                else{  // Fail
                    AppData.showGenericAlert("Error", message: "Fetching the capability token is failed. You will need to login again")
                    
                    //Logout
                    let deadlineTime = DispatchTime.now() + .seconds(1)
                    DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                        
                        AppDelegate.shared.logout()
                    }
                    
                }
            }
        }
        else{
            if self.device == nil {
                self.device = TCDevice(capabilityToken: strCapabilityToken!, delegate: self)
            }
            else {
                self.device!.updateCapabilityToken(strCapabilityToken!)
            }
            
            //If startConnect is true, start connect!
            if startConnect == true {
                self.connectWithParams(params: params)
            }

        }
        
        
        
    }
    
    func connectWithParams(params dictParams:Dictionary<String,String> = Dictionary<String,String>()) {
        if !self.capabilityTokenValid() {
            AppData.sharedInstance.setUserCapabilityToken("")
            AppData.sharedInstance.setTwilioClientID("")
            self.login(startConnect: true, params : dictParams)
            
            return;
        }
        
        if (dictParams["To"] != nil) {
            self.phoneNumberToCall = dictParams["To"]!
        }
        else{
            AppData.showGenericAlert("Error", message: "<To> param shouldn't be empty")
            
            return;
        }
        
        //Check if the device is valid
        if self.device == nil {
            return;
        }
        
        //Disconnect all connections
        self.device?.disconnectAll()
        if self.connection != nil {
            self.connection.disconnect()
        }
        
        //Try to connect
        self.connection = self.device?.connect(dictParams, delegate: self)
        
        self.showCallUI()
    }
    
    // MARK: - Call UI
    
    func showCallUI() {
        self.device?.unlisten()
        
        //Show a call in the interface
        self.showCallingView()
        
        //Show a call using CallKit
        startCallWithCallKit()
    }
    
    func startNewCall(phoneNumber : String) {
        
        
        let callCount = callManager?.calls.count ?? 0
        
        if callCount == 0  {
            let params : Dictionary = ["To" : phoneNumber, "From" : "client:" + AppData.sharedInstance.twilioClientID()!]
            //Call with Twilio
            self.connectWithParams(params: params);
            
        }
    }

    
    
    
    // MARK: - TCConnection Delegate
    
    
    
    public func connectionDidConnect(_ connection: TCConnection) {
        print("--------------TCConnection Connected...");
        
        //Set the microphone according to the current state
        if self.connection?.state == TCConnectionState.connected {
            
            let btnMic : JCPadButton = callPad.buttons.first as! JCPadButton
            if btnMic.input == "M_ON" {
                self.connection?.isMuted = false
            }
            else {
                self.connection?.isMuted = true
            }
        }
        
        //Set Speaker according to the user's initial information
        let btnAudio : JCPadButton = callPad.buttons[1] as! JCPadButton
        var speakerEnabled = false
        if btnAudio.input == "A_ON" {
            speakerEnabled = true
        }
        else{
            speakerEnabled = false
        }
        
        //Make on audio
        do {
            try self.setSpeaker(enabled: speakerEnabled)
        } catch let err {
            print(err)
        }
        
        //Change the top text of call view
        self.changeTextInCallView(newText: phoneNumberToCall)

    }
    
    public func connectionDidStartConnecting(_ connection: TCConnection) {
        print("--------------TCConnection DidStartConnecting...");
        
    }
    
    public func connection(_ connection: TCConnection, didFailWithError error: Error?) {
        
        print("--------------TCConnection didFailWithError: \(error)")
        
        AppData.showGenericAlert("Error", message: "Call Error : \((error?.localizedDescription)!)")
        
        if receiveCall != nil && (receiveCall.superview != nil){
            receiveCall.removeFromSuperview()
        }
        
        if callPad != nil && (callPad.superview != nil){
            callPad.removeFromSuperview()
        }
        
        //Remove Calling Screen from the interface
        callPad.removeFromSuperview()
        
        //Show a call end with CallKit
        self.endCallWithCallKit()
        self.device?.listen()
    }
    
    public func connectionDidDisconnect(_ connection: TCConnection) {
        print("--------------TCConnection Did Disconnected");
        
        
        if receiveCall != nil && (receiveCall.superview != nil){
            receiveCall.removeFromSuperview()
        }
        
        if callPad != nil && (callPad.superview != nil){
            callPad.removeFromSuperview()
        }
        
        //Show a call end with CallKit
        self.endCallWithCallKit()
        self.device?.listen()
    }
    
    // MARK: - Connection Delegate End
    
    
    func acceptConnection() {
        print("--------------Incoming Call is accepted");
        self.connection = self.pendingConnection
        self.connection.delegate = self;
        self.pendingConnection = nil
        
        self.connection?.accept()
    }
    
    func rejectConnection() {
        self.pendingConnection?.reject()
        self.pendingConnection = nil
    }
    
    func ignoreConnection() {
        self.pendingConnection?.ignore()
        self.pendingConnection = nil
    }
    
    func sendInput(input:String) {
        if self.connection != nil {
            self.connection!.sendDigits(input)
        }
    }
    
    func setSpeaker(enabled:Bool) throws {
        if self.connection != nil {
            if (enabled)
            {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.speaker);
            } else {
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.none);
            }
        }
    }
    
    func muteConnection(mute:Bool) {
        if self.connection != nil {
            self.connection!.isMuted = mute;
        }
    }

    func capabilityTokenValid()->(Bool) {
        var isValid:Bool = false
    
        if self.device != nil {
            let capabilities = self.device!.capabilities! as NSDictionary
        
            let expirationTimeObject:NSNumber = capabilities.object(forKey: "expiration") as! NSNumber
            let expirationTimeValue:Int64 = expirationTimeObject.int64Value
            let currentTimeValue:TimeInterval = NSDate().timeIntervalSince1970
        
            if (expirationTimeValue-Int64(currentTimeValue)) > 0 {
                isValid = true
            }
        }
    
        return isValid
    }
    
    
    // MARK: - TCDevice Delegate
    public func deviceDidStartListening(forIncomingConnections device: TCDevice)->() {
        print("--------------Started listening for incoming connections");
    }
    
    public func device(_ device: TCDevice, didStopListeningForIncomingConnections error: Error?) {
        print("--------------Stopped listening for incoming connections");
    }
    
    public func device(_ device:TCDevice, didReceiveIncomingConnection connection:TCConnection)->() {
        print("--------------Receiving an incoming connection");
        
        self.pendingConnection = connection
        if self.connection?.state == TCConnectionState.connected{
            self.rejectConnection()
            return
        }
        
        //Show the local notification for incoming call
        NotificationCenter.default.post(
            name: receivingIncomingCallNotification,
            object: nil)
        
        //Show the calling screen
        let callerNumber : String? = connection.parameters?.value(forKey: "From") as? String
        self.showCallReceivingView(callerNumber: callerNumber)
        
        //Show calling screen with CallKit
        let backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
        DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now()) {
            AppDelegate.shared.displayIncomingCall(uuid: UUID(), handle: callerNumber!, hasVideo: false) { _ in
                UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            }
        }
    }
    
    
    
    
    
    
    // MARK: - JCDialPad Delegate
    public func dialPad(_ dialPad: JCDialPad!, shouldInsertText text: String!, forButtonPress button: JCPadButton!) -> Bool {
        
        
        if text == "A" { //Accept the incoming call
            self.acceptConnection()
            DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now()) {
                self.receiveCall.removeFromSuperview();
            }
            
            self.showCallUI()
        }
        else if text == "C" { //Cancel the call
            self.device?.disconnectAll()
            self.endCallWithCallKit()
            self.device?.listen()
            
            self.changeTextInCallView(newText: "Call Ended!")
            
            let deadlineTime = DispatchTime.now() + .seconds(3)
            DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                if self.receiveCall.superview != nil {
                    self.receiveCall.removeFromSuperview()
                }
                else if self.callPad.superview != nil{
                    self.callPad.removeFromSuperview()
                }
            }
            
            self.device?.listen()
            
        }
        else if text == "M_ON" {
            if self.connection?.state == TCConnectionState.connected {
                //Make off microphone
                self.connection?.isMuted = true
            }
            
            //Change the microphone button
            var arrayButtons : Array = self.callPad.buttons
            arrayButtons.removeFirst()
            arrayButtons.insert(self.microphoneOffButton(), at: 0)
            self.callPad.buttons = arrayButtons;
            self.callPad.layoutSubviews()
        }
        else if text == "M_OFF" {
            if self.connection?.state == TCConnectionState.connected {
                //Make on microphone
                self.connection?.isMuted = false
            }
            
            //Change the microphone button
            var arrayButtons : Array = self.callPad.buttons
            arrayButtons.removeFirst()
            arrayButtons.insert(self.microphoneButton(), at: 0)
            self.callPad.buttons = arrayButtons;
            self.callPad.layoutSubviews()
        }
        else if text == "A_ON" {
            if self.connection?.state == TCConnectionState.connected {
                //Make off audio
                
                do {
                    try self.setSpeaker(enabled: false)
                } catch let err {
                    print(err)
                }
                
            }
            
            //Change the microphone button
            var arrayButtons : Array = self.callPad.buttons
            arrayButtons.remove(at: 1)
            arrayButtons.insert(self.audioOffButton(), at: 1)
            self.callPad.buttons = arrayButtons;
            self.callPad.layoutSubviews()
        }
        else if text == "A_OFF" {
            if self.connection?.state == TCConnectionState.connected {
                //Make on audio
                
                do {
                    try self.setSpeaker(enabled: true)
                } catch let err {
                    print(err)
                }
                
            }
            
            //Change the microphone button
            var arrayButtons : Array = self.callPad.buttons
            arrayButtons.remove(at: 1)
            arrayButtons.insert(self.audioButton(), at: 1)
            self.callPad.buttons = arrayButtons;
            self.callPad.layoutSubviews()
        }
        
        return false;
    }
    
    
    // MARK: - IncomingConnection Notification
    
    func pendingIncomingConnectionReceived(notification:NSNotification) {
        if UIApplication.shared.applicationState != UIApplicationState.active
        {
            let notification:UILocalNotification = UILocalNotification()
            notification.alertBody = "Incoming Call"
            UIApplication.shared.presentLocalNotificationNow(notification)
        }
    }
    
    // MARK: - CallKit Management
    func startCallWithCallKit() {
        callManager?.startCall(handle: phoneNumberToCall, video: false)
        
        
    }
    
    func endCallWithCallKit() {
        
        let callCount = callManager?.calls.count ?? 0
        if callCount > 0 {
            callManager?.end(call: (callManager?.calls[0])!)
        }
    }
    
    // MARK: - Setup Call UI
    
    func showCallReceivingView(callerNumber : String?) {
        phoneNumberToCall = callerNumber!
        
        //Show a call in the interface
        callPad = JCDialPad.init(frame: (AppDelegate.shared.window?.rootViewController?.view.bounds)!)
        
        let buttons : Array = [self.microphoneButton(), self.audioOffButton(), self.callStartButton(), self.callEndButton()]
        
        callPad.buttons = buttons
        
        let backgroundView : UIImageView = UIImageView.init(image: UIImage.init(named: "wallpaper"))
        backgroundView.contentMode = UIViewContentMode.scaleAspectFill
        callPad.backgroundView = backgroundView
        callPad.showDeleteButton = false
        
        self.changeTextInCallView(newText: "Receiving a calling from " + callerNumber!)
        callPad.formatTextToPhoneNumber = true
        callPad.delegate = self;
        
        AppDelegate.shared.window?.rootViewController?.view.addSubview(callPad)
    }
    
    func showCallingView() {
        //Show a call in the interface
        callPad = JCDialPad.init(frame: (AppDelegate.shared.window?.rootViewController?.view.bounds)!)
        
        let buttons : Array = [self.microphoneButton(), self.audioOffButton(), self.callEndButton()]
        
        callPad.buttons = buttons
        
        let backgroundView : UIImageView = UIImageView.init(image: UIImage.init(named: "wallpaper"))
        backgroundView.contentMode = UIViewContentMode.scaleAspectFill
        callPad.backgroundView = backgroundView
        callPad.showDeleteButton = false
        
        self.changeTextInCallView(newText: "Calling...")
        callPad.formatTextToPhoneNumber = true
        callPad.delegate = self;
        
        AppDelegate.shared.window?.rootViewController?.view.addSubview(callPad)
    }
    
    func changeTextInCallView(newText : String) {
        callPad.digitsTextField.text = newText
    }
    
    func callStartButton() -> JCPadButton
    {
        let iconView : FIIconView = FIIconView.init(frame: CGRect.init(x: 0, y: 0, width: 65, height: 65))
        iconView.backgroundColor = UIColor.clear
        iconView.icon = FIFontAwesomeIcon.phone()
        iconView.padding = 15;
        iconView.iconColor = UIColor.green
        
        let button : JCPadButton = JCPadButton.init(input: "A", iconView: iconView, subLabel: "")
        button.backgroundColor = UIColor.clear
        button.borderColor = UIColor.green
        return button;
    }
    
    func callEndButton() -> JCPadButton
    {
        let iconView : FIIconView = FIIconView.init(frame: CGRect.init(x: 0, y: 0, width: 65, height: 65))
        iconView.backgroundColor = UIColor.clear
        iconView.icon = FIFontAwesomeIcon.phone()
        iconView.padding = 15;
        iconView.iconColor = UIColor.white
        
        let button : JCPadButton = JCPadButton.init(input: "C", iconView: iconView, subLabel: "")
        button.backgroundColor = UIColor.red//UIColor.init(red: 0.261, green: 0.837, blue: 0.319, alpha: 1.000)
        button.borderColor = UIColor.red//UIColor.init(red: 0.261, green: 0.837, blue: 0.319, alpha: 1.000)
        return button;
    }
    func microphoneButton() -> JCPadButton
    {
        let iconView : FIIconView = FIIconView.init(frame: CGRect.init(x: 0, y: 0, width: 65, height: 65))
        iconView.backgroundColor = UIColor.clear
        iconView.icon = FIFontAwesomeIcon.microphone()
        iconView.padding = 15;
        iconView.iconColor = UIColor.white
        
        let button : JCPadButton = JCPadButton.init(input: "M_ON", iconView: iconView, subLabel: "")
        button.backgroundColor = UIColor.clear//UIColor.init(red: 0.261, green: 0.837, blue: 0.319, alpha: 1.000)
        button.borderColor = UIColor.white//UIColor.init(red: 0.261, green: 0.837, blue: 0.319, alpha: 1.000)
        return button;
    }
    func microphoneOffButton() -> JCPadButton
    {
        let iconView : FIIconView = FIIconView.init(frame: CGRect.init(x: 0, y: 0, width: 65, height: 65))
        iconView.backgroundColor = UIColor.clear
        iconView.icon = FIFontAwesomeIcon.microphoneOff()
        iconView.padding = 15;
        iconView.iconColor = UIColor.white
        
        let button : JCPadButton = JCPadButton.init(input: "M_OFF", iconView: iconView, subLabel: "")
        button.backgroundColor = UIColor.clear//UIColor.init(red: 0.261, green: 0.837, blue: 0.319, alpha: 1.000)
        button.borderColor = UIColor.white//UIColor.init(red: 0.261, green: 0.837, blue: 0.319, alpha: 1.000)
        return button;
    }
    func audioButton() -> JCPadButton
    {
        let iconView : FIIconView = FIIconView.init(frame: CGRect.init(x: 0, y: 0, width: 65, height: 65))
        iconView.backgroundColor = UIColor.clear
        iconView.icon = FIFontAwesomeIcon.volumeUp()
        iconView.padding = 15;
        iconView.iconColor = UIColor.white
        
        let button : JCPadButton = JCPadButton.init(input: "A_ON", iconView: iconView, subLabel: "")
        button.backgroundColor = UIColor.clear//UIColor.init(red: 0.261, green: 0.837, blue: 0.319, alpha: 1.000)
        button.borderColor = UIColor.white//UIColor.init(red: 0.261, green: 0.837, blue: 0.319, alpha: 1.000)
        return button;
    }
    func audioOffButton() -> JCPadButton
    {
        let iconView : FIIconView = FIIconView.init(frame: CGRect.init(x: 0, y: 0, width: 65, height: 65))
        iconView.backgroundColor = UIColor.clear
        iconView.icon = FIFontAwesomeIcon.volumeOff()
        iconView.padding = 15;
        iconView.iconColor = UIColor.white
        
        let button : JCPadButton = JCPadButton.init(input: "A_OFF", iconView: iconView, subLabel: "")
        button.backgroundColor = UIColor.clear//UIColor.init(red: 0.261, green: 0.837, blue: 0.319, alpha: 1.000)
        button.borderColor = UIColor.white//UIColor.init(red: 0.261, green: 0.837, blue: 0.319, alpha: 1.000)
        return button;
    }

    
    
    // MARK: CXCallObserverDelegate
    
    func handleCallsChangedNotification(notification: NSNotification) {
        
    }
}
