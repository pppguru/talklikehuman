//
//  ContactViewController.swift
//  TalkLikeHumans
//
//  Created by ppp on 8/12/16.
//  Copyright © 2016 Expert Dev. All rights reserved.
//

import UIKit


class ContactViewController: UIViewController{
    
    var contactInfo                         : EPContact!
    
    @IBOutlet weak var imgProfilePhoto      : UIImageView!
    @IBOutlet weak var lblName              : UILabel!
    @IBOutlet weak var lblPosition          : UILabel!
    @IBOutlet weak var lblPhoneNumber       : UILabel!
    @IBOutlet weak var contactInitialLabel  : UILabel!
    
    var phone                               : Phone!
    var phoneNumberToCall                   : String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        
        self.phone = AppData.sharedInstance.phone
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppData.sharedInstance.reportScreenNameToGAI("Contact Detail Screen");
        
        self.navigationController?.isNavigationBarHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - User Interaction
    
    @IBAction func didTapCall(_ sender : UIButton) {
        let phoneNumberCount = contactInfo.phoneNumbers.count
        if phoneNumberCount > 0  {
            phoneNumberToCall = "\(contactInfo.phoneNumbers[0].phoneNumber)"
        }
        else {
            AppData.showGenericAlert("Error", message: "Phone Number is not available.")
            return
        }
        
        //TESTING - Manually set it to the specific number
//        phoneNumberToCall = "+1 720-370-4078"
//        phoneNumberToCall = "+86 183-4251-0860"
        phoneNumberToCall = "+1 720-330-8544"
//        phoneNumberToCall = "+1 720 370 4078"

        
        
        //Clear up the phone number
        //        let stringArray = phoneNumberToCall.components(separatedBy:NSCharacterSet.decimalDigits.inverted)
        //        phoneNumberToCall = stringArray.joined(separator: "")
        
        //Call with Twilio
        self.phone.startNewCall(phoneNumber: phoneNumberToCall)
        
        //Disable the call button
//        navigationItem.rightBarButtonItems?.first?.isEnabled = false;
    }
    
        
    // MARK: - Setup UI
    
    func updateInitialsColorForRandomColor() {
        //Applies color to Initial Label
        let colorArray = [EPGlobalConstants.Colors.amethystColor,EPGlobalConstants.Colors.asbestosColor,EPGlobalConstants.Colors.emeraldColor,EPGlobalConstants.Colors.peterRiverColor,EPGlobalConstants.Colors.pomegranateColor,EPGlobalConstants.Colors.pumpkinColor,EPGlobalConstants.Colors.sunflowerColor]
        let randomValue = Int(arc4random_uniform(UInt32(colorArray.count)))
        contactInitialLabel.backgroundColor = colorArray[randomValue]
    }
    
    func setupUI(){
        if contactInfo == nil {
            AppData.showGenericAlert("Error", message: "Fetching the contact info is failed.")
            return;
        }
        
        if contactInfo.thumbnailProfileImage != nil {
            imgProfilePhoto.layer.cornerRadius = imgProfilePhoto.frame.width / 2.0
            imgProfilePhoto.layer.masksToBounds = true
            
            imgProfilePhoto.image = contactInfo.thumbnailProfileImage
            imgProfilePhoto.isHidden = false
            contactInitialLabel.isHidden = true
        } else {
            contactInitialLabel.layer.cornerRadius = contactInitialLabel.frame.width / 2.0
            contactInitialLabel.layer.masksToBounds = true

            contactInitialLabel.text = contactInfo.contactInitials()
            self.updateInitialsColorForRandomColor()
            imgProfilePhoto.isHidden = true
            contactInitialLabel.isHidden = false
        }

        
        
        
        lblName.text = contactInfo.displayName()
        lblPosition.text = contactInfo.company! as String
        
        let phoneNumberCount = contactInfo.phoneNumbers.count
        if phoneNumberCount == 1  {
            self.lblPhoneNumber.text = "\(contactInfo.phoneNumbers[0].phoneNumber)"
        }
        else if phoneNumberCount > 1 {
            self.lblPhoneNumber.text = "\(contactInfo.phoneNumbers[0].phoneNumber) and \(contactInfo.phoneNumbers.count-1) more"
        }
        else {
            self.lblPhoneNumber.text = EPGlobalConstants.Strings.phoneNumberNotAvaialable
        }
        
        //Initialize the right nav button
        let play = UIBarButtonItem(title: "Call", style: .plain, target: self, action: #selector(didTapCall))
        navigationItem.rightBarButtonItems = [play]
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
