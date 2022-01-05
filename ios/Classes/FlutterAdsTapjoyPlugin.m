#import "FlutterAdsTapjoyPlugin.h"

@protocol FlutterAdsTapjoyPluginProtocol
+ (void)connectSuccessTapjoyChannel:(NSNotification *)notifyObj;
+ (void)connectFailTapjoyChannel:(NSNotification *)notifyObj;
@end

@implementation FlutterAdsTapjoyPlugin
  FlutterMethodChannel* channel;
  FlutterViewController* viewController;
  NSDictionary* placements;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  channel = [FlutterMethodChannel
      methodChannelWithName:@"flutter_ads_tapjoy"
            binaryMessenger:[registrar messenger]];
  FlutterAdsTapjoyPlugin* instance = [[FlutterAdsTapjoyPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];

  viewController = [[FlutterViewController alloc] initWithProject:nil nibName:nil bundle:nil];
  placements = [[NSMutableDictionary alloc]initWithCapacity:100];

  [[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(connectSuccessTapjoyChannel:) name:TJC_CONNECT_SUCCESS object:nil ];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectFailTapjoyChannel:) name:TJC_CONNECT_FAILED object:nil];
  [Tapjoy setDefaultViewController:viewController];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  NSDictionary *dict = call.arguments;
  NSString *placementName = dict[@"placementName"];
  if ([@"connectTapjoy" isEqualToString:call.method]) {
    NSString *apiKey = dict[@"iOSSDKKey"];
    NSNumber *methodDebug = dict[@"debug"];
    [Tapjoy setDebugEnabled:methodDebug.boolValue];
    [Tapjoy connect:apiKey];
    result(@YES);
  } else if ([@"setUserID" isEqualToString:call.method]) {
    NSString *userID = dict[@"userID"];
    [Tapjoy setUserID:userID];
    result(@YES);
  } else if ([@"isConnected" isEqualToString:call.method]) {
    BOOL isConnected = [Tapjoy isConnected];
    if (isConnected) {
      result(@YES);
    } else {
       result(@NO);
    }
  } else if ([@"setUserConsent" isEqualToString:call.method]) {
    BOOL userConsent = dict[@"userConsent"];
    NSString* userConsentStr = userConsent ? @"1" : @"0";
    TJPrivacyPolicy *privacyPolicy = [Tapjoy getPrivacyPolicy];
    [privacyPolicy setUserConsent: userConsentStr];
    result(@YES);
  } else if ([@"setSubjectToGDPR" isEqualToString:call.method]) {
     BOOL gdpr = dict[@"gdpr"];
     TJPrivacyPolicy *privacyPolicy = [Tapjoy getPrivacyPolicy];
     [privacyPolicy setSubjectToGDPR: gdpr];
     result(@YES);
  } else if ([@"setBelowConsentAge" isEqualToString:call.method]) {
     BOOL belowConsentAge = dict[@"belowConsentAge"];
     TJPrivacyPolicy *privacyPolicy = [Tapjoy getPrivacyPolicy];
     [privacyPolicy setBelowConsentAge: belowConsentAge];
     result(@YES);
  } else if ([@"setUSPrivacy" isEqualToString:call.method]) {
     NSString* usPrivacy = dict[@"usPrivacy"];
     TJPrivacyPolicy *privacyPolicy = [Tapjoy getPrivacyPolicy];
     [privacyPolicy setUSPrivacy: usPrivacy];
     result(@YES);
  } else if ([@"createPlacement" isEqualToString:call.method]) {
    [FlutterAdsTapjoyPlugin addPlacement:placementName];
    result(@YES);
  } else if ([@"requestContent" isEqualToString:call.method]) {
    TJPlacement *myPlacement = placements[placementName];
    if (myPlacement) {
      [myPlacement requestContent];
    } else {
      NSDictionary *args;
      args = @{ @"error" : @"Placement Not Found, Please Add placement first",@"placementName":placementName};
      [channel invokeMethod:@"requestFail" arguments:args];
    }
  } else if ([@"showPlacement" isEqualToString:call.method]) {
    TJPlacement *myPlacement = placements[placementName];
    [myPlacement showContentWithViewController:viewController];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

+ (void)connectSuccessTapjoyChannel:(NSNotification *)notifyObj {
    [channel invokeMethod:@"connectionSuccess" arguments:nil];
}

+ (void)connectFailTapjoyChannel:(NSNotification *)notifyObj {
    [channel invokeMethod:@"connectionFail" arguments:nil];
}

+ (void)requestDidSucceed:(TJPlacement*)placement {
    NSDictionary *args;
    [args setValue:placement.placementName forKey:@"placementName"];
    [channel invokeMethod:@"requestSuccess" arguments:args];
}

// Called when there was a problem during connecting Tapjoy servers.
+ (void)requestDidFail:(TJPlacement*)placement error:(NSError*)error {
    NSDictionary *args = @{ @"placementName" : placement.placementName, @"error":error.description};
    [channel invokeMethod:@"requestFail" arguments:args];
}

// Called when the content is actually available to display.
+ (void)contentIsReady:(TJPlacement*)placement {
    NSDictionary *args = @{ @"placementName" : placement.placementName};
    [channel invokeMethod:@"contentReady" arguments:args];
}

// Called when the content is showed.
+ (void)contentDidAppear:(TJPlacement*)placement {
    NSDictionary *args = @{ @"placementName" : placement.placementName};
    [channel invokeMethod:@"contentDidAppear" arguments:args];
}

// Called when the content is dismissed.
+ (void)contentDidDisappear:(TJPlacement*)placement {
    NSDictionary *args = @{ @"placementName" : placement.placementName};
    [channel invokeMethod:@"contentDidDisappear" arguments:args];
}

+ (void)addPlacement:(NSString*)placementName {
    TJPlacement *myPlacement = [TJPlacement placementWithName:placementName delegate:self];
    [placements setValue:myPlacement forKey:placementName];
}

@end
