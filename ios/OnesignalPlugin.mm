#import "OnesignalPlugin.h"
#import <OneSignal/OneSignal.h>

@implementation OnesignalPlugin

// The plugin must call super dealloc.
- (void) dealloc {
  [super dealloc];
}

// The plugin must call super init.
- (id) init {
  self = [super init];
  if (!self) {
    return nil;
  }
  return self;
}

- (void) initializeWithManifest:(NSDictionary *)manifest appDelegate:(TeaLeafAppDelegate *)appDelegate {
  @try {
    // TODO: Make it enabed based on a flag
    // ONLY DURING DEBUG
    // [OneSignal setLogLevel: ONE_S_LL_VERBOSE visualLevel: ONE_S_LL_DEBUG];

    NSDictionary *ios = [manifest valueForKey:@"ios"];
    NSString *onesignalAppId = [ios valueForKey:@"onesignalAppID"];
    NSDictionary *launchOptions = appDelegate.startOptions;
    NSDictionary *apsData = [launchOptions valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (apsData) {
      [self sendNotificationResponse:nil launchData: apsData];
    }

    // TODO: Since launchOptions is being passed, handleNotificationAction should be called, investigate
    [OneSignal initWithLaunchOptions:launchOptions
               appId:onesignalAppId
               handleNotificationReceived:^(OSNotification *notification) {
                 NSLog(@"Received Notification - %@", notification.payload.notificationID);
                 // TODO: Handle notification received
               }
               handleNotificationAction:^(OSNotificationOpenedResult *result) {
                 OSNotificationPayload* payload = result.notification.payload;
                 [self sendNotificationResponse:payload launchData:nil];
               }
               // TODO: Make requesting permissions configurable
               settings:@{kOSSettingsKeyInFocusDisplayOption : @(OSNotificationDisplayTypeNotification),
                          kOSSettingsKeyAutoPrompt : @NO}
    ];
    NSLog(@"{onesignal} initDone");
  }
  @catch (NSException *exception) {
    NSLog(@"{onesignal} Failed to initialize with exception: %@", exception);
  }
}

- (void) sendNotificationResponse: (OSNotificationPayload *)payload launchData:(NSDictionary *) data {
  NSMutableDictionary *notification_data;
  NSString *jsonString;
  NSString *subtitle;
  NSString *launchURL;
  NSDictionary *additionalData;

  // TODO: Verify and test launchURL
  if (payload) {
    subtitle = payload.subtitle;
    launchURL = payload.launchURL;
    additionalData = payload.additionalData;
    notification_data = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                         payload.notificationID, @"notification_id",
                         payload.title, @"title",
                         payload.body, @"body",
                         nil];
  } else {
    NSDictionary *alert = data[@"aps"][@"alert"];
    NSDictionary *custom = data[@"custom"];

    subtitle = alert[@"subtitle"];
    launchURL = custom[@"u"];
    additionalData = custom[@"a"];
    notification_data = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                         custom[@"i"], @"notification_id",
                         alert[@"title"], @"title",
                         alert[@"body"], @"body",
                         nil];
  }

  if(subtitle) {
    [notification_data setValue:subtitle forKey: @"subtitle"];
  }
  if(launchURL) {
    [notification_data setValue:launchURL forKey: @"launch_url"];
  }
  if(additionalData) {
    jsonString = [self getJSONStringFromDict:additionalData];

    if (jsonString) {
      [notification_data setValue:jsonString forKey: @"additional_data"];
    }
  }

  jsonString = [self getJSONStringFromDict:notification_data];

  if (jsonString) {
    [[PluginManager get] dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
                                            @"onesignalNotificationOpened", @"name",
                                            jsonString, @"notification_data",
                                            NO, @"failed", nil]];
  }
}

- (NSString *) getJSONStringFromDict: (NSDictionary*) dict {
  NSData *jsonData;
  NSString *jsonString;
  NSError *error;

  jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                  options:NSJSONWritingPrettyPrinted
                                  error:&error];
  if (jsonData) {
    jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  } else {
    NSLog(@"{onesignal} Got a json error: %@", error);
    jsonString = nil;
  }
  return jsonString;
}

- (void) didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken application:(UIApplication *)app {
}

- (void) didFailToRegisterForRemoteNotificationsWithError:(NSError *)error application:(UIApplication *)app {
  NSLog(@"{onesignal} didFailtoRegisterforremotenotifications: %@", error);
}

- (void) didReceiveRemoteNotification:(NSDictionary *)userInfo application:(UIApplication *)app {
}

- (void) sendUserTags:( NSDictionary *)tags {
  [OneSignal sendTags: tags];
  NSLog(@"tags: %@", tags);
}
@end
