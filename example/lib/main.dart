import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_ads_tapjoy/flutter_ads_tapjoy.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _tapjoyInitialized = 'not initialized';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String intialized = "not initialized";
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      await FlutterAdsTapjoy.setUserConsent(true);
      await FlutterAdsTapjoy.setUserID("UserID");
      //TODO:set SDK Key
      bool ret =
          await FlutterAdsTapjoy.connect(
              androidSDKKey: "Tapjoy Android SDK key",
              iOSSDKKey: "Tapjoy iOS SDK Key",
              debug: true) ?? false;
      if (ret) {
        intialized = "initialized";
        //TODO: set offerwall placement key
        await FlutterAdsTapjoy.addPlacement("Tapjoy placement key");
      }
    } on PlatformException {
      intialized = 'not initialized';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _tapjoyInitialized = intialized;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child:Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            Text('Running on: $_tapjoyInitialized\n'),
            _createButton("request offerwall", () { FlutterAdsTapjoy.reqeustContent("of_pl");}),
            SizedBox(height: 30,),
            _createButton("show offerwall", () { FlutterAdsTapjoy.showtContent("of_pl");}),
          ],
        )),
      ),
    );
  }

  Widget _createButton(String text, VoidCallback cb) {
    return GestureDetector(
        onTap: cb,
        child: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.redAccent,
          ),
          child: Text(text, style: TextStyle(color: Colors.white),),
        ));
  }
}
