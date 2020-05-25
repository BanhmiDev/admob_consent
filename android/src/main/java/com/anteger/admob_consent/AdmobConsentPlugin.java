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
package com.anteger.admob_consent;

import android.app.Activity;

import androidx.annotation.NonNull;

import com.anteger.admob_consent.ConsentForm;
import com.anteger.admob_consent.ConsentFormListener;
import com.anteger.admob_consent.ConsentInfoUpdateListener;
import com.anteger.admob_consent.ConsentInformation;
import com.anteger.admob_consent.ConsentStatus;
import com.anteger.admob_consent.DebugGeography;

import java.net.MalformedURLException;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.BinaryMessenger;

/** AdmobConsentPlugin */
public class AdmobConsentPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {

  private MethodChannel methodChannel;
  private Activity activity;

  /** Plugin registration. */
  public static void registerWith(PluginRegistry.Registrar registrar) {
    final AdmobConsentPlugin instance = new AdmobConsentPlugin();
    instance.onAttachedToEngine(registrar.activity(), registrar.messenger());
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    methodChannel = new MethodChannel(binding.getBinaryMessenger(), "admob_consent");
    methodChannel.setMethodCallHandler(this);
  }

  private void onAttachedToEngine(Activity activity, BinaryMessenger messenger) {
    methodChannel = new MethodChannel(messenger, "admob_consent");
    methodChannel.setMethodCallHandler(this);
    this.activity = activity;
  }

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {
    activity = null;
    methodChannel.setMethodCallHandler(null);
    methodChannel = null;
  }

  @Override
  public void onAttachedToActivity(ActivityPluginBinding activityPluginBinding) {
    // Plugin is now attached to an Activity
    activity = activityPluginBinding.getActivity();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    // The Activity your plugin was attached to was
    // destroyed to change configuration.
    // This call will be followed by onReattachedToActivityForConfigChanges().
    activity = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding activityPluginBinding) {
    // TODO: your plugin is now attached to a new Activity
    // after a configuration change.
    activity = activityPluginBinding.getActivity();
  }

  @Override
  public void onDetachedFromActivity() {
    activity = null;
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("show")) {
      showConsent(call);
      result.success(null);
    } else {
      result.notImplemented();
    }
  }

  ConsentForm form;

  private void showConsent(MethodCall call) {
    if (activity == null) return; // No activity

    final String publisherId = call.argument("publisherId");
    final String privacyURL = call.argument("privacyURL");
    URL tmpPrivacyURL = null;
    try {
      tmpPrivacyURL = new URL(privacyURL);
    } catch (MalformedURLException e) {
      // Error
      Map<String, Object> args = new HashMap<>();
      args.put("message", "Invalid privacy URL");
      methodChannel.invokeMethod("onConsentFormError", args);
      return;
    }
    final URL realPrivacyURL = tmpPrivacyURL;
    ConsentInformation consentInformation = ConsentInformation.getInstance(activity);
    String[] publisherIds = {publisherId};
    consentInformation.requestConsentInfoUpdate(publisherIds, new ConsentInfoUpdateListener() {
        @Override
        public void onConsentInfoUpdated(ConsentStatus consentStatus) {
          // User's consent status successfully updated.
          // Create form
          form = new ConsentForm.Builder(activity, realPrivacyURL).withListener(new ConsentFormListener() {
            @Override
            public void onConsentFormLoaded() {
                // Consent form loaded successfully.
                methodChannel.invokeMethod("onConsentFormLoaded", null);
                form.show();
            }

            @Override
            public void onConsentFormOpened() {
                // Consent form was displayed.
                methodChannel.invokeMethod("onConsentFormOpened", null);
            }

            @Override
            public void onConsentFormClosed(ConsentStatus consentStatus, Boolean userPrefersAdFree) {
                // Consent form was closed.
                // Return false if status NON_PERSONALIZED/UNKNOWN
                Map<String, Object> args = new HashMap<>();
                args.put("shouldPersonalize", (consentStatus == ConsentStatus.PERSONALIZED));
                methodChannel.invokeMethod("onConsentFormClosed", args);
            }

            @Override
            public void onConsentFormError(String errorDescription) {
              Map<String, Object> args = new HashMap<>();
              args.put("message", errorDescription);
              methodChannel.invokeMethod("onConsentFormError", args);
            }
          })
          .withPersonalizedAdsOption()
          .withNonPersonalizedAdsOption()
          .build();
          form.load();
        }

        @Override
        public void onFailedToUpdateConsentInfo(String errorDescription) {
          // User's consent status failed to update.
          Map<String, Object> args = new HashMap<>();
          args.put("message", errorDescription);
          methodChannel.invokeMethod("onConsentFormError", args);
        }
    });
  }
}
