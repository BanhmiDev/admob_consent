import 'package:flutter/material.dart';
import 'dart:async';

import 'package:admob_consent/admob_consent.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  AdmobConsent _admobConsent = AdmobConsent();
  late StreamSubscription<void> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = _admobConsent.onConsentFormObtained.listen((o) {
      // Obtained consent
    });
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    _admobConsent.show();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _admobConsent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('An example app'),
        ),
      ),
    );
  }
}
