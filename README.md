# Admob Consent Plugin

![Pub Version](https://img.shields.io/pub/v/admob_consent)

User Messaging Platform wrapper used for consent gathering (i.e. GDPR) on Android and iOS. **NEW:** now uses Google's new `User Messaging Platform` with `Funding Choices`.

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

If you intend to use this SDK for Apple's new ATT requirement (iOS 14+), add the following to `Info.plist`. More information [here](https://support.google.com/fundingchoices/answer/9995402).

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```

### Example

```dart
import 'package:flutter/material.dart';
import 'package:admob_consent/admob_consent.dart';

final AdmobConsent _admobConsent = AdmobConsent();
_admobConsent.show();
```

### Listener
You can listen to the ```onConsentFormLoaded```, ```onConsentFormOpened```, ```onConsentFormObtained``` and ```onConsentFormError``` streams.

``` dart
_admobConsent.onConsentFormObtained.listen((o) {
  // Obtained consent
});
```

## Enjoy it?
<a href="https://www.buymeacoffee.com/AntegerDigital" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png" alt="Buy Me A Coffee" style="height: 41px !important;width: 174px !important;"></a>

## Troubleshooting
### Consent form does not show up in Android release builds
You most likely have to fiddle with proguards to keep some classes from being obfuscated or disable ```minifyEnabled```.

```
# Keep classes of this plugin
-keep class com.anteger.** { *; }

# Gson uses generic type information stored in a class file when working with fields. Proguard
# removes such information by default, so configure it to keep all of it.
-keepattributes Signature

# For using GSON @Expose annotation
-keepattributes *Annotation*

# Gson specific classes
-dontwarn sun.misc.**
#-keep class com.google.gson.stream.** { *; }

# Application classes that will be serialized/deserialized over Gson
-keep class com.google.gson.examples.android.model.** { <fields>; }

# Prevent proguard from stripping interface information from TypeAdapter, TypeAdapterFactory,
# JsonSerializer, JsonDeserializer instances (so they can be used in @JsonAdapter)
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Prevent R8 from leaving Data object members always null
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
```
