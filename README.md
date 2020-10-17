# Admob Consent Plugin

![Pub Version](https://img.shields.io/pub/v/admob_consent)

User Messaging Platform wrapper used for consent gathering (i.e. GDPR, ATT or both) on Android and iOS. Uses Google's new `User Messaging Platform` with `Funding Choices`.

## Screenshots

| Example 1 | Example 2 |
| :-------: | :-------: |
| ![Example 1](https://www.anteger.com/images/uploads/admob_consent_example_2.png) | ![Example 2](https://www.anteger.com/images/uploads/admob_consent_example.png) |

## Usage
To use this plugin, add `admob_consent` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

## Requirements

### 1. Funding Choices

* Create a [Funding Choices account](https://support.google.com/fundingchoices/answer/9180084)
* Create respective messages inside Funding Choices for your desired app and publish them

### 2. Android Setup

Make sure to have added your [app ID](https://support.google.com/admob/answer/7356431) to `AndroidManifest.xml`.

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="YOUR-APP-ID"/>
```

### 3. iOS Setup

Make sure to have added your [app ID](https://support.google.com/admob/answer/7356431) to `Info.plist`.

```xml
<key>GADApplicationIdentifier</key>
<string>YOUR-APP-ID</string>
```

### 3.1 iOS ATT Dialog
If you intend to use this SDK for Apple's new ATT requirement (iOS 14+), add the following to `Info.plist`. If you have the IDFA message enabled in Funding Choices, the ATT dialog will appear automatically after it within your app. More information [here](https://support.google.com/fundingchoices/answer/9995402).

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```

Next, you'll need to link the `AppTrackingTransparency` framework by going to your application's target in Xcode and clicking the plus icon on `Frameworks, Libraries and Embedded Content` tab. See Google's guide [here](https://developers.google.com/admob/ump/ios/quick-start#app_tracking_transparency).

### Example

```dart
import 'package:flutter/material.dart';
import 'package:admob_consent/admob_consent.dart';

final AdmobConsent _admobConsent = AdmobConsent();
_admobConsent.show();
```

### Listener
You can listen to the ```onConsentFormLoaded```, ```onConsentFormOpened```, ```onConsentFormObtained``` and ```onConsentFormError``` streams. The UMP SDK should handle most of the things though.

``` dart
_admobConsent.onConsentFormObtained.listen((o) {
  // Obtained consent
});
```

## Enjoy it?
<a href="https://www.buymeacoffee.com/AntegerDigital" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png" alt="Buy Me A Coffee" style="height: 41px !important;width: 174px !important;"></a>
