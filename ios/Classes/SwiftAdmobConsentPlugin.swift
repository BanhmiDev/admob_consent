/*
 * Copyright 2020 Son Nguyen
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import Flutter
import UIKit
import UserMessagingPlatform
//import FBSDKCoreKit.FBSDKSettings

public class SwiftAdmobConsentPlugin: NSObject, FlutterPlugin {
  
  //var registrar: FlutterPluginRegistrar?
  var viewController: UIViewController?
  var channel = FlutterMethodChannel()

  init(viewController: UIViewController?, channel: FlutterMethodChannel) {
      super.init()
      //self.registrar = registrar
      self.viewController = viewController
      self.channel = channel
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "admob_consent", binaryMessenger: registrar.messenger())
    let viewController = UIApplication.shared.delegate?.window??.rootViewController
    let instance = SwiftAdmobConsentPlugin(viewController: viewController, channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if (call.method == "show") {
      showConsent(call);
      result(nil)
    }
  }

  private func showConsent(_ call: FlutterMethodCall) {
    guard let args = call.arguments as? Dictionary<String, Any> else {
      let data: [String:Any] = ["message": "Invalid call arguments"] // Used for invoke methods (listeners)
      self.channel.invokeMethod("onConsentFormError", arguments: data)
      return
    }

    let presentedViewController = self.viewController?.presentedViewController
    let currentViewController: UIViewController? = presentedViewController ?? self.viewController
    if currentViewController == nil {
      let data: [String:Any] = ["message": "Invalid view controller"] // Used for invoke methods (listeners)
      self.channel.invokeMethod("onConsentFormError", arguments: data)
      return
    }

    let forceShow = (args["forceShow"] as! Bool)
    
    let parameters = UMPRequestParameters()
    parameters.tagForUnderAgeOfConsent = false
    UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters, completionHandler: {(error) in
        if (error as NSError?) != nil {
            // Consent info update error
            let data: [String:Any] = ["message": "Consent info fetch failed"] // Used for invoke methods (listeners)
            self.channel.invokeMethod("onConsentFormError", arguments: data)
        } else {
            // Consent info update success
            self.channel.invokeMethod("onConsentFormLoaded", arguments: nil)
            let formStatus = UMPConsentInformation.sharedInstance.formStatus
            if formStatus == .available {
                self.channel.invokeMethod("onConsentFormAvailable", arguments: nil)
              // Load form
              self.loadForm(currentViewController: currentViewController!, forceShow: forceShow)
            }
        }
    })
  }

  private func loadForm(currentViewController: UIViewController, forceShow: Bool) {
    UMPConsentForm.load(completionHandler: {(form, loadError) in
        if (loadError as NSError?) != nil {
            // Form load error
            let data: [String:Any] = ["message": "Consent form failed"] // Used for invoke methods (listeners)
            self.channel.invokeMethod("onConsentFormError", arguments: data)
        } else {
            // Form load success
            self.channel.invokeMethod("onConsentFormOpened", arguments: nil)

            if UMPConsentInformation.sharedInstance.consentStatus == .required || forceShow {
              // Consent required, first time opening form
              form?.present(from: currentViewController, completionHandler: {(dismissError) in
                if UMPConsentInformation.sharedInstance.consentStatus == .obtained {
                  // Obtained consent from form
                  //Settings.setAdvertiserTrackingEnabled(UMPConsentInformation.sharedInstance.consentType == .personalized)
                  //let data: [String:Any] = ["consent": UMPConsentInformation.sharedInstance.consentType == .personalized] // Use
                  self.channel.invokeMethod("onConsentFormObtained", arguments: nil)
                }
              })
            }
        }
    })
  }
}
