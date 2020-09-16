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
    let presentedViewController = self.viewController?.presentedViewController
    let currentViewController: UIViewController? = presentedViewController ?? self.viewController as? UIViewController

    // Should not happen, but anyway
    if currentViewController == nil {
      let data: [String:Any] = ["message": "Invalid view controller"] // Used for invoke methods (listeners)
      self.channel.invokeMethod("onConsentFormError", arguments: data)
      return
    }
    
    let parameters = UMPRequestParameters()
    parameters.tagForUnderAgeOfConsent = false
    UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters, completionHandler: {(error) in
        if let error = error as NSError? {
            // Consent info update error
            let data: [String:Any] = ["message": "Consent info fetch failed"] // Used for invoke methods (listeners)
            self.channel.invokeMethod("onConsentFormError", arguments: data)
        } else {
            // Consent info update success
            self.channel.invokeMethod("onConsentFormLoaded", arguments: nil)
            let formStatus = UMPConsentInformation.sharedInstance.formStatus
            if formStatus == .available {
              // Load form
              self.loadForm(currentViewController: currentViewController!)
            }
        }
    })
  }

  private func loadForm(currentViewController: UIViewController) {
    UMPConsentForm.load(completionHandler: {(form, loadError) in
        if let error = loadError as NSError? {
            // Form load error
            let data: [String:Any] = ["message": "Consent form failed"] // Used for invoke methods (listeners)
            self.channel.invokeMethod("onConsentFormError", arguments: data)
        } else {
            // Form load success
            self.channel.invokeMethod("onConsentFormOpened", arguments: nil)

            if UMPConsentInformation.sharedInstance.consentStatus == .required {
              // Consent required, first time opening form
              form?.present(from: currentViewController, completionHandler: {(dismissError) in
                if UMPConsentInformation.sharedInstance.consentStatus == .obtained {
                  // Obtained consent from form
                  self.channel.invokeMethod("onConsentFormObtained", arguments: nil)
                }
              })
            } else if UMPConsentInformation.sharedInstance.consentStatus == .obtained {
              // Already obtained previously, display form to let user manage/change consent
              form?.present(from: currentViewController, completionHandler: {(dismissError) in
                  if UMPConsentInformation.sharedInstance.consentStatus == .obtained {
                    self.channel.invokeMethod("onConsentFormObtained", arguments: nil)
                  }
              })
            }
        }
    })
  }
}
