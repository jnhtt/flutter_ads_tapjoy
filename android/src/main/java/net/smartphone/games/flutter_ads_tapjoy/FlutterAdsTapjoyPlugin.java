package net.smartphone.games.flutter_ads_tapjoy;

import android.app.Activity;
import android.content.Context;

import androidx.annotation.NonNull;

import com.tapjoy.TJActionRequest;
import com.tapjoy.TJAwardCurrencyListener;
import com.tapjoy.TJConnectListener;
import com.tapjoy.TJEarnedCurrencyListener;
import com.tapjoy.TJError;
import com.tapjoy.TJGetCurrencyBalanceListener;
import com.tapjoy.TJPlacement;
import com.tapjoy.TJPlacementListener;
import com.tapjoy.TJSpendCurrencyListener;
import com.tapjoy.TJPrivacyPolicy;
import com.tapjoy.Tapjoy;
import com.tapjoy.TapjoyConnectFlag;

import java.util.Hashtable;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.Log;

/** FlutterAdsTapjoyPlugin */
public class FlutterAdsTapjoyPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private Context context;
  private Hashtable<String, TJPlacement> placements = new Hashtable<String, TJPlacement>();

  private  static Activity activity;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "flutter_ads_tapjoy");
    channel.setMethodCallHandler(this);

    context = flutterPluginBinding.getApplicationContext();
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    Log.i("flutter_ads_tapjoy", call.method);
    switch (call.method) {
      case "connectTapjoy":
        Tapjoy.setActivity(activity);
        final String sdkKey = call.argument("androidSDKKey");
        final boolean enableLog = call.argument("enableLog");
        final String enableLogStr = enableLog ? "true" : "false";
        final boolean debug = call.argument("debug");
        Hashtable<String, Object> connectFlags = new Hashtable<String, Object>();
        connectFlags.put(TapjoyConnectFlag.ENABLE_LOGGING, enableLog);
        Tapjoy.setDebugEnabled(debug);
        boolean ret = Tapjoy.connect(context, sdkKey, connectFlags, new TJConnectListener() {
          @Override
          public void onConnectSuccess() {
            sendToFlutter("connectionSuccess", null);
          }

          @Override
          public void onConnectFailure() {
            sendToFlutter("connectionFail", null);
          }
        });
        Tapjoy.setEarnedCurrencyListener(new TJEarnedCurrencyListener() {
          @Override
          public void onEarnedCurrency(String currencyName, int amount) {
            Hashtable<String, Object> getCurrencyResponse = new Hashtable<String, Object>();
            getCurrencyResponse.put("currencyName",currencyName);
            getCurrencyResponse.put("earnedAmount",amount);
            sendToFlutter("onEarnedCurrency", getCurrencyResponse);
          }
        });
        result.success(ret);
        break;
      case "setUserID":
        final String userID = call.argument("userID");
        Tapjoy.setUserID(userID);
        result.success(true);
        break;
      case "isConnected":
        result.success(Tapjoy.isConnected());
        break;
      case "setSubjectToGDPR": {
          final boolean gdpr = call.argument("gdpr");
          TJPrivacyPolicy privacyPolicy = Tapjoy.getPrivacyPolicy();
          privacyPolicy.setSubjectToGDPR(gdpr);
        result.success(true);
        }
        break;
      case "setUserConsent": {
          final boolean userConsent = call.argument("userConsent");//"0" or "1"
          TJPrivacyPolicy privacyPolicy = Tapjoy.getPrivacyPolicy();
          privacyPolicy.setUserConsent(userConsent ? "1" : "0");
          result.success(true);
        }
        break;
      case "setBelowConsentAge": {
          final boolean belowConsentAge = call.argument("belowConsentAge");
          TJPrivacyPolicy privacyPolicy = Tapjoy.getPrivacyPolicy();
          privacyPolicy.setBelowConsentAge(belowConsentAge);
          result.success(true);
        }
        break;
      case "setUSPrivacy": {
          final String usPrivacy = call.argument("usPrivacy");
          TJPrivacyPolicy privacyPolicy = Tapjoy.getPrivacyPolicy();
          privacyPolicy.setUSPrivacy(usPrivacy);
          result.success(true);
        }
        break;
      case "createPlacement":
        final String placementName = call.argument("placementName");
        TJPlacementListener placementListener = new TJPlacementListener() {
          @Override
          public void onRequestSuccess(final TJPlacement placement) {
            final Hashtable<String, Object> map = new Hashtable<String, Object>();
            map.put("placementName", placement.getName());
            sendToFlutter("requestSuccess", map);
          }

          @Override
          public void onRequestFailure(TJPlacement placement, TJError error) {
            final Hashtable<String, Object> map = new Hashtable<String, Object>();
            map.put("placementName", placement.getName());
            map.put("error", error.message);
            sendToFlutter("requestFail", map);
          }

          @Override
          public void onContentReady(TJPlacement placement) {
            final Hashtable<String, Object> map = new Hashtable<String, Object>();
            map.put("placementName", placement.getName());
            sendToFlutter("contentReady", map);
          }

          @Override
          public void onContentShow(TJPlacement placement) {
            final Hashtable<String, Object> map = new Hashtable<String, Object>();
            map.put("placementName", placement.getName());
            sendToFlutter("contentDidAppear", map);
          }

          @Override
          public void onContentDismiss(TJPlacement placement) {
            final Hashtable<String, Object> map = new Hashtable<String, Object>();
            map.put("placementName", placement.getName());
            sendToFlutter("contentDidDisappear", map);

          }

          @Override
          public void onPurchaseRequest(TJPlacement placement, TJActionRequest actionRequest, String s) {

          }

          @Override
          public void onRewardRequest(TJPlacement placement, TJActionRequest actionRequest, String s, int i) {

          }

          @Override
          public void onClick(TJPlacement placement) {
            final Hashtable<String, Object> map = new Hashtable<String, Object>();
            map.put("placementName",placement.getName());
            sendToFlutter("clicked", map);
          }
        };
        TJPlacement p = Tapjoy.getPlacement(placementName, placementListener);
        placements.put(placementName, p);
        result.success(p.isContentAvailable());
        break;
      case "requestContent":
        final String placementNameRequest = call.argument("placementName");
        final TJPlacement placementRequest = placements.get(placementNameRequest);
        if (placementRequest != null) {
          placementRequest.requestContent();
        } else {
          final Hashtable<String, Object> map = new Hashtable<String, Object>();
          map.put("placementName", placementNameRequest);
          map.put("error", "Placement Not Found, Please Add placement first");
          sendToFlutter("requestFail", map);
        }
        break;
      case "showPlacement":
        final String placementNameShow = call.argument("placementName");
        final TJPlacement placementShow = placements.get(placementNameShow);
        placementShow.showContent();
        break;
      default:
        result.notImplemented();
      break;
    }
  }

  @Override
  public void onAttachedToActivity(@NonNull  ActivityPluginBinding binding) {
    FlutterAdsTapjoyPlugin.activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull  ActivityPluginBinding binding) {
    FlutterAdsTapjoyPlugin.activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {

  }


  @Override
  public void onDetachedFromActivity() {
  }

  void sendToFlutter(@NonNull final String methodName, final Hashtable data) {
    try {
      FlutterAdsTapjoyPlugin.activity.runOnUiThread(new Runnable() {@Override
      public void run() {
        channel.invokeMethod(methodName,data);
      }
      });
    } catch(final Exception e) {
      Log.e("FlutterAdsTapjoyPlugin", "Error " + e.toString());
    }
  }
}
