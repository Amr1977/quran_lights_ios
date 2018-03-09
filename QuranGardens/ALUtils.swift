//
//  ALUtils.swift
//  ParkCar
//
//  Created by   Amr Lotfy on 11/25/17.
//  Copyright © 2017 Vlad. All rights reserved.
//

import UIKit
import AVFoundation
import MBProgressHUD

struct ALUtils {
    static func rateApp(appId: String, completion: ((_ success: Bool)->())? = nil) {
        //let appUrl = "itms-apps://itunes.apple.com/app/" + appId
        let appUrl = "https://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=\(appId)&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8"
        //TODO: use &action=write-review for opening review directly
        print("app review URL: ", appUrl)
        
        gotoURL(string: appUrl, completion: completion)
    }
    
    static func gotoURL(string: String, completion: ((_ success: Bool)->())? = nil) {
        print("gotoURL: ", string)
        guard let url = URL(string: string) else {
            print("gotoURL: invalid url", string)
            completion?(false)
            return
        }
        if #available(iOS 10, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: completion)
        } else {
            completion?(UIApplication.shared.openURL(url))
        }
    }
    
    static func gotoApp(appID: String, completion: ((_ success: Bool)->())? = nil) {
        let appUrl = "itms://itunes.apple.com/us/app/apple-store/id\(appID)?mt=8"
        
        gotoURL(string: appUrl, completion: completion)
    }
    
    static func bounce(view: UIView?, completion: ((Bool) -> ())? = nil) {
        view?.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 2.0,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 6.0,
                       options: .allowUserInteraction,
                       animations: {
                        view?.transform = .identity
        },
                       completion: completion)
    }
    
    static func printFonts() {
        let fontFamilyNames = UIFont.familyNames
        for familyName in fontFamilyNames {
            print("------------------------------")
            print("Font Family Name = [\(familyName)]")
            let names = UIFont.fontNames(forFamilyName: familyName as! String)
            print("Font Names = [\(names)]")
        }
    }
    
    static func bottomPadding() -> CGFloat {
        var padding: CGFloat = 0.0
        
        if #available(iOS 11.0, *) {
            if let window = UIApplication.shared.keyWindow {
                padding = window.safeAreaInsets.bottom
            }
        }
        
        return padding
    }
    
    static let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    
    static let synthesizer = AVSpeechSynthesizer()
    static func say(_ text: String, _ tts: Bool = false){
        print(text)
        if !tts { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        synthesizer.speak(utterance)
    }
    
}


extension UIViewController {
    
    func showToast(message : String) {
        
        DispatchQueue.main.async {
            let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
            
            toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
            toastLabel.textColor = UIColor.white
            toastLabel.textAlignment = .center;
            toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
            
            toastLabel.text = message
            toastLabel.alpha = 1.0
            toastLabel.layer.cornerRadius = 10;
            toastLabel.clipsToBounds  =  true
            toastLabel.sizeToFit()
            var frame = toastLabel.frame
            frame.size.width += 20
            frame.size.height += 20
            toastLabel.frame = frame
            
            toastLabel.center = self.view.center
            self.view.addSubview(toastLabel)
            UIView.animate(withDuration: 5.0, delay: 0.1, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0.0
            }, completion: {(isCompleted) in
                toastLabel.removeFromSuperview()
            })
        }
        
        
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}


