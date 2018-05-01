//
//  SplashViewController.swift
//  TalkLikeHumans
//
//  Created by ppp on 8/11/16.
//  Copyright © 2016 Roy Emerson. All rights reserved.
//

import UIKit
//import SwiftyGif
import Foundation

class SplashViewController: UIViewController {

    @IBOutlet weak var animatedImageView : UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Show the animated splash
//        let gifmanager = SwiftyGifManager(memoryLimit:100)
//        let gif = UIImage(gifName: "animationsplash")
//        animatedImageView.setGifImage(gif, manager: gifmanager, loopCount: 1)
        
        let url : URL = Bundle.main.url(forResource: "animationsplash", withExtension: "gif")!
        let testImage : UIImage = UIImage.animatedImage(withAnimatedGIFURL: url)
        self.animatedImageView.animationImages = testImage.images
        self.animatedImageView.animationDuration = 1.5
        self.animatedImageView.animationRepeatCount = 1;
        self.animatedImageView.image = testImage.images?.last;
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.animatedImageView.startAnimating()
        self.perform(#selector(goBack), with: nil, afterDelay: 2.0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppData.sharedInstance.reportScreenNameToGAI("Splash Screen");
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func goBack(){
        self.navigationController?.popViewController(animated: false);
    }
    
    

}
