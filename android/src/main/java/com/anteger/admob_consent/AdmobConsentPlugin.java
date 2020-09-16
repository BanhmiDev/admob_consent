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

import com.google.android.ump.ConsentForm;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.FormError;
import com.google.android.ump.UserMessagingPlatform;

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

  private ConsentInformation consentInformation;
  private ConsentForm consentForm;

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

  private void showConsent(MethodCall call) {
    if (activity == null) return; // No activity
    ConsentRequestParameters params = new ConsentRequestParameters.Builder().build();
    consentInformation = UserMessagingPlatform.getConsentInformation(activity);
    consentInformation.requestConsentInfoUpdate(
      activity,
      params,
      new ConsentInformation.OnConsentInfoUpdateSuccessListener() {
        @Override
        public void onConsentInfoUpdateSuccess() {
            methodChannel.invokeMethod("onConsentFormLoaded", null);
            // The consent information state was updated.
            // You are now ready to check if a form is available.
            if (consentInformation.isConsentFormAvailable()) {
              // Load form
              loadForm();
            }
        }
      },
      new ConsentInformation.OnConsentInfoUpdateFailureListener() {
        @Override
        public void onConsentInfoUpdateFailure(FormError formError) {
          Map<String, Object> args = new HashMap<>();
          args.put("message", formError.getMessage());
          methodChannel.invokeMethod("onConsentFormError", args);
        }
      }
    );
  }

  private void loadForm() {
    UserMessagingPlatform.loadConsentForm(
      activity,
      new UserMessagingPlatform.OnConsentFormLoadSuccessListener() {
        @Override
        public void onConsentFormLoadSuccess(ConsentForm consentForm) {
          methodChannel.invokeMethod("onConsentFormOpened", null);
          consentForm = consentForm;
          if (consentInformation.getConsentStatus() == ConsentInformation.ConsentStatus.REQUIRED) {
            // Not obtained yet, first time
            consentForm.show(
              activity,
              new ConsentForm.OnConsentFormDismissedListener() {
                  @Override
                  public void onConsentFormDismissed(FormError formError) {
                    // Handle dismissal by reloading form.
                    loadForm();
                  }
              }
            );
          }
          if (consentInformation.getConsentStatus() == ConsentInformation.ConsentStatus.OBTAINED) {
            // Already obtained, possibility to manage/change settings
            consentForm.show(
              activity,
              new ConsentForm.OnConsentFormDismissedListener() {
                  @Override
                  public void onConsentFormDismissed(FormError formError) {
                    methodChannel.invokeMethod("onConsentFormObtained", null);
                  }
              }
            );
          }
        }
      },
      new UserMessagingPlatform.OnConsentFormLoadFailureListener() {
        @Override
        public void onConsentFormLoadFailure(FormError formError) {
          Map<String, Object> args = new HashMap<>();
          args.put("message", formError.getMessage());
          methodChannel.invokeMethod("onConsentFormError", args);
        }
      }
    );
  }
}
