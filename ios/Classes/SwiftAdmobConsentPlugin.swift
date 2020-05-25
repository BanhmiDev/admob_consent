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
import PersonalizedAdConsent

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
    let currentViewController: UIViewController? = presentedViewController ?? self.viewController as? UIViewController

    // Should not happen, but anyway
    if currentViewController == nil {
      let data: [String:Any] = ["message": "Invalid view controller"] // Used for invoke methods (listeners)
      self.channel.invokeMethod("onConsentFormError", arguments: data)
      return
    }

    PACConsentInformation.sharedInstance.requestConsentInfoUpdate(
      forPublisherIdentifiers: [(args["publisherId"] as! String)])
    {(_ error: Error?) -> Void in
      if let error = error {
        // Consent info update failed.            
        let data: [String:Any] = ["message": "Consent info fetch failed"] // Used for invoke methods (listeners)
        self.channel.invokeMethod("onConsentFormError", arguments: data)
      } else {
        // Consent info update succeeded. The shared PACConsentInformation
        // instance has been updated.
        guard let privacyUrl = URL(string: (args["privacyURL"] as! String)),
            let form = PACConsentForm(applicationPrivacyPolicyURL: privacyUrl) else {
            let data: [String:Any] = ["message": "Invalid privacy URL"] // Used for invoke methods (listeners)
            self.channel.invokeMethod("onConsentFormError", arguments: data)
            return
        }
        form.shouldOfferPersonalizedAds = true
        form.shouldOfferNonPersonalizedAds = true
        form.load {(_ error: Error?) -> Void in
          if let error = error {
            // Error
            let data: [String:Any] = ["message": "\(error)"] // Used for invoke methods (listeners)
            self.channel.invokeMethod("onConsentFormError", arguments: data)
          } else {
            self.channel.invokeMethod("onConsentFormLoaded", arguments: nil)
            self.channel.invokeMethod("onConsentFormOpened", arguments: nil)
            // Success load, present
            form.present(from: currentViewController!) { (error, userPrefersAdFree) in
              if let error = error {
                // Error
                let data: [String:Any] = ["message": "\(error)"] // Used for invoke methods (listeners)
                self.channel.invokeMethod("onConsentFormError", arguments: data)
              } else if userPrefersAdFree {
                // User prefers to use a paid version of the app.
                // TODO
              } else {
                // Check the user's consent choice.
                var data: [String:Any] = [:] // Used for invoke methods (listeners)
                let status = PACConsentInformation.sharedInstance.consentStatus
                data["shouldPersonalize"] = !(status == PACConsentStatus.nonPersonalized || status == PACConsentStatus.unknown)
                self.channel.invokeMethod("onConsentFormClosed", arguments: data)
              }
            }
          }
        }
      }
    }
  }
}
