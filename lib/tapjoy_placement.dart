import 'dart:async';
import 'dart:io';
import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/services.dart';

enum TapjoyConnectionResult { connected, disconnected }

enum TapjoyContentState {
  contentReady,
  contentDidAppear,
  contentDidDisappear,
  contentRequestSuccess,
  contentRequestFail,
  userClickedAndroidOnly,
}

enum IOSATTAuthResult {
  notDetermined,
  restricted,
  denied,
  authorized,
  none,
  iOSVersionNotSupported,
  android
}

typedef void TapjoyPlacementHandler(
    TapjoyContentState contentState,
    String? placementName,
    String? error,
    );

class TapjoyPlacement {
  final String name;
  final MethodChannel channel;
  TapjoyPlacementHandler? handler;

  void setHandler(TapjoyPlacementHandler myHandler) {
    handler = myHandler;
  }

  TapjoyPlacement({required this.channel, required this.name}) {
  }

  Future<void> requestContent() async {
    await channel.invokeMethod('requestContent', <String, dynamic>{
      'placementName': name,
    });
  }

  Future<void> showPlacement() async {
    await channel.invokeMethod('showPlacement', <String, dynamic>{
      'placementName': name,
    });
  }
}
