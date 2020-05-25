#import "AdmobConsentPlugin.h"
#if __has_include(<admob_consent/admob_consent-Swift.h>)
#import <admob_consent/admob_consent-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "admob_consent-Swift.h"
#endif

@implementation AdmobConsentPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftAdmobConsentPlugin registerWithRegistrar:registrar];
}
@end
