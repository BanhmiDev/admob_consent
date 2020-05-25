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
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdmobConsent {
  final MethodChannel _channel;

  final _onConsentFormLoaded = StreamController<Null>.broadcast();
  final _onConsentFormOpened = StreamController<Null>.broadcast();
  final _onConsentFormClosed = StreamController<bool>.broadcast();
  final _onConsentFormError = StreamController<bool>.broadcast();

  static AdmobConsent _instance;

  factory AdmobConsent() {
    if (_instance == null) {
      const MethodChannel methodChannel = const MethodChannel('admob_consent');
      _instance = AdmobConsent.private(methodChannel);
    }
    return _instance;
  }

  @visibleForTesting
  AdmobConsent.private(this._channel) {
    _channel.setMethodCallHandler(_handleMessages);
  }

  /// Handles calls from the native side
  Future<Null> _handleMessages(MethodCall call) async {
    switch (call.method) {
      case 'onConsentFormLoaded':
        _onConsentFormLoaded.add(null);
        break;
      case 'onConsentFormOpened':
        _onConsentFormOpened.add(null);
        break;
      case 'onConsentFormClosed':
        _onConsentFormClosed.add(call.arguments['shouldPersonalize']);
        break;
      case 'onConsentFormError':
        _onConsentFormError.add(call.arguments['message']);
        break;
    }
  }

  /// Shows admob consent form for the given publisherId
  Future<Null> show(
          {@required String publisherId, @required String privacyURL}) async =>
      await _channel.invokeMethod(
          'show', {'publisherId': publisherId, 'privacyURL': privacyURL});

  /// Returns true when the form has been loaded
  Stream<Null> get onConsentFormLoaded => _onConsentFormLoaded.stream;

  /// Returns true when the consent form has been opened
  Stream<Null> get onConsentFormOpened => _onConsentFormOpened.stream;

  /// Returns true if personalized ads should be used
  Stream<bool> get onConsentFormClosed => _onConsentFormClosed.stream;

  /// Returns an error message when an error has occurred
  Stream<dynamic> get onConsentFormError => _onConsentFormError.stream;

  void dispose() {
    _onConsentFormLoaded.close();
    _onConsentFormOpened.close();
    _onConsentFormClosed.close();
    _onConsentFormError.close();
    _instance = null;
  }
}
