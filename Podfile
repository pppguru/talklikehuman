platform :ios, '10.0'
use_frameworks!
source 'https://github.com/CocoaPods/Specs.git'
target 'TalkLikeHumans' do

pod 'Alamofire', :git => 'https://github.com/Alamofire/Alamofire.git'
pod 'SVProgressHUD'
pod 'Google/SignIn'
pod 'Google/Analytics'
pod 'TwilioSDK'
pod 'JCDialPad'
pod 'FontasticIcons'
pod 'ReachabilitySwift', :git => 'https://github.com/ashleymills/Reachability.swift.git'

end

post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        # Configure Pod targets for Xcode 8 compatibility
        config.build_settings['SWIFT_VERSION'] = '3.0'
        config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = 'U2W7FGGVN3/'
        config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
    end
end
