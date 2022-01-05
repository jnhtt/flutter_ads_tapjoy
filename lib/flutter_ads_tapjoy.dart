import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/services.dart';
import 'package:flutter_ads_tapjoy/tapjoy_placement.dart';

typedef void TapjoyConnectionResultHandler(TapjoyConnectionResult connectionResult);

class FlutterAdsTapjoy {
  static const MethodChannel _channel = MethodChannel('flutter_ads_tapjoy');
  static List<TapjoyPlacement> _placements = [];

  static TapjoyConnectionResultHandler? _connectionResultHandler;

  static Future<bool?> connect({
    required String androidSDKKey,
    required String iOSSDKKey,
    required bool debug}) async {
    _channel.setMethodCallHandler(_handleMethod);
    final bool? connectionResult =
    await _channel.invokeMethod('connectTapjoy', <String, dynamic>{
      'androidSDKKey': androidSDKKey,
      "iOSSDKKey": iOSSDKKey,
      "debug": debug,//TODO: production need false
      "enableLog": true,//TODO: production need false
    });
    return connectionResult;
  }
  static Future<bool?> isConnected() async {
    return await _channel.invokeMethod('isConnected');
  }
  static Future<void> setUserID(String userID) async {
    await _channel.invokeMethod('setUserID', <String, dynamic>{
      'userID': userID,
    });
  }
  static Future<void> setUserConsent(bool userConsent) async {
    await _channel.invokeMethod('setUserConsent', <String, dynamic>{
      'userConsent': userConsent,
    });
  }
  static Future<void> setSubjectToGDPR(bool gdpr) async {
    await _channel.invokeMethod('setSubjectToGDPR', <String, dynamic>{
      'gdpr': gdpr,
    });
  }
  static Future<void> setBelowConsentAge(bool belowConsentAge) async {
    await _channel.invokeMethod('setBelowConsentAge', <String, dynamic>{
      'belowConsentAge': belowConsentAge,
    });
  }
  static Future<void> subjectToUSPrivacy(String confirm) async {
    await _channel.invokeMethod('setUSPrivacy', <String, dynamic>{
      'usPrivacy': confirm,
    });
  }
  static Future<bool?> addPlacement(String placementName) async {
    TapjoyPlacement placement = TapjoyPlacement(channel: _channel, name: placementName);
    _placements.add(placement);
    return await _createPlacement(placement);
  }
  static Future<void> reqeustContent(String placementName) async {
    TapjoyPlacement? placement = _placements
        .firstWhereOrNull((element) => element.name == placementName);
    if (placement != null) {
      placement.requestContent();
    } else {
      print("not found : " + placementName);
    }
  }
  static Future<void> showtContent(String placementName) async {
    TapjoyPlacement? placement = _placements
        .firstWhereOrNull((element) => element.name == placementName);
    if (placement != null) {
      placement.showPlacement();
    } else {
      print("not found : " + placementName);
    }
  }
  static Future<IOSATTAuthResult> getIOSATTAuth() async {
    if (Platform.isIOS) {
      final String? result = await _channel.invokeMethod("getATT");
      switch (result) {
        case "NotDetermined":
          return IOSATTAuthResult.notDetermined;
        case "Restricted":
          return IOSATTAuthResult.restricted;
        case "Denied":
          return IOSATTAuthResult.denied;
        case "Authorized":
          return IOSATTAuthResult.authorized;
        case "NOT":
          return IOSATTAuthResult.iOSVersionNotSupported;
        default:
          return IOSATTAuthResult.none;
      }
    } else {
      return IOSATTAuthResult.android;
    }
  }

  static void setConnectionResultHandler(TapjoyConnectionResultHandler handler) {
    _connectionResultHandler = handler;
  }

  static Future<void> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'connectionSuccess':
        if (_connectionResultHandler != null) {
          _connectionResultHandler!(TapjoyConnectionResult.connected);
        }
        break;
      case 'connectionFail':
        if (_connectionResultHandler != null) {
          _connectionResultHandler!(TapjoyConnectionResult.disconnected);
        }
        break;
      case 'requestSuccess':
        String? placementName = call.arguments["placementName"];
        TapjoyPlacement? placement = _placements
            .firstWhereOrNull((element) => element.name == placementName);

        if (placement != null) {
          if (placement.handler != null) {
            placement.handler!(
                TapjoyContentState.contentRequestSuccess, placementName, null);
          } else {}
        }
        break;
      case 'requestFail':
        String? placementName = call.arguments["placementName"];
        TapjoyPlacement? placement = _placements
            .firstWhereOrNull((element) => element.name == placementName);
        String? error = call.arguments["error"];
        if (placement != null) {
          if (placement.handler != null) {
            placement.handler!(
                TapjoyContentState.contentRequestFail, placementName, error);
          } else {}
        }
        break;
      case 'contentReady':
        String? placementName = call.arguments["placementName"];
        TapjoyPlacement? placement = _placements
            .firstWhereOrNull((element) => element.name == placementName);

        if (placement != null) {
          if (placement.handler != null) {
            placement.handler!(
                TapjoyContentState.contentReady, placementName, null);
          } else {}
        }
        break;
      case 'contentDidAppear':
        String? placementName = call.arguments["placementName"];
        TapjoyPlacement? placement = _placements
            .firstWhereOrNull((element) => element.name == placementName);

        if (placement != null) {
          if (placement.handler != null) {
            placement.handler!(
                TapjoyContentState.contentDidAppear, placementName, null);
          } else {}
        }
        break;
      case 'clicked':
        String? placementName = call.arguments["placementName"];
        TapjoyPlacement? placement = _placements
            .firstWhereOrNull((element) => element.name == placementName);

        if (placement != null) {
          if (placement.handler != null) {
            placement.handler!(
                TapjoyContentState.userClickedAndroidOnly, placementName, null);
          } else {}
        }
        break;
      case 'contentDidDisappear':
        String? placementName = call.arguments["placementName"];
        TapjoyPlacement? placement = _placements
            .firstWhereOrNull((element) => element.name == placementName);

        if (placement != null) {
          if (placement.handler != null) {
            placement.handler!(
                TapjoyContentState.contentDidDisappear, placementName, null);
          } else {}
        }
        break;
      default:
        break;
    }
    return null;
  }

  static Future<bool?> _createPlacement(TapjoyPlacement placement) async {
    final result = await _channel.invokeMethod('createPlacement', <String, dynamic>{
      'placementName': placement.name,
    });
    return result;
  }
}
