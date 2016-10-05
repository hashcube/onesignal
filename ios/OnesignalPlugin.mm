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
    //ONLY DURING DEBUG
    //[OneSignal setLogLevel: ONE_S_LL_VERBOSE visualLevel: ONE_S_LL_DEBUG];

    NSDictionary *ios = [manifest valueForKey:@"ios"];
    NSString *onesignalAppId = [ios valueForKey:@"onesignalAppID"];
    NSDictionary *launchOptions = appDelegate.startOptions;
    NSDictionary *apsData = [launchOptions valueForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (apsData) {
      [self showAlert: @"launchdata present, wohooo!"];
      [self sendNotificationResponse:nil launchData: apsData];
    }

    // TODO: Since launchOptions is being passed, handleNotificationAction should be called, investigate?
    [OneSignal initWithLaunchOptions:launchOptions
               appId:onesignalAppId
               handleNotificationReceived:^(OSNotification *notification) {
                 NSLog(@"Received Notification - %@", notification.payload.notificationID);
                 //TODO: Handle notification received
               }
               handleNotificationAction:^(OSNotificationOpenedResult *result) {
                 OSNotificationPayload* payload = result.notification.payload;
                 [self sendNotificationResponse:payload launchData:nil];
               }
               settings:@{kOSSettingsKeyInFocusDisplayOption : @(OSNotificationDisplayTypeNotification), kOSSettingsKeyAutoPrompt : @NO}
    ];
    NSLog(@"{onesignal} initDone");
  }
  @catch (NSException *exception) {
    NSLog(@"{onesignal} Failed to initialize with exception: %@", exception);
  }
}

- (void) sendNotificationResponse: (OSNotificationPayload *)payload launchData:(NSDictionary *) data {
  NSMutableDictionary *notification_data;
  NSString * where;
  NSError *error;
  NSData *jsonData;
  NSString *jsonString;
  NSString *subtitle;
  NSString *launchURL;
  NSDictionary *additionalData;

  if (payload) {
    where = @"payload not nil";
      subtitle = payload.subtitle;
      launchURL = payload.launchURL;
      additionalData = payload.additionalData;
    notification_data = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                         payload.notificationID, @"notification_id",
                         payload.title, @"title",
                         payload.body, @"body",
                         nil];
  } else {
    where = @"launchData not nil";
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
    [notification_data setValue:additionalData forKey: @"additional_data"];
  }
  jsonData = [NSJSONSerialization dataWithJSONObject:notification_data
                                  options:NSJSONWritingPrettyPrinted
                                  error:&error];
  [self showAlert:[NSString stringWithFormat:@"response: %@, %@", where, notification_data]];

  if (! jsonData) {
    NSLog(@"{gamethrive} Got a json error: %@", error);
  } else {
    jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
      [[PluginManager get] dispatchJSEvent:[NSDictionary dictionaryWithObjectsAndKeys:
                                            @"onesignalNotificationOpened", @"name",
                                            jsonString, @"notification_data",
                                            NO, @"failed", nil]];
  }
}

- (void) showAlert: (NSString*) message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Debug"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

- (void) didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken application:(UIApplication *)app {
}

- (void) didFailToRegisterForRemoteNotificationsWithError:(NSError *)error application:(UIApplication *)app {
  NSLog(@"{onesignal} didFailtoRegisterforremotenotifications: %@", error);
}

- (void) didReceiveRemoteNotification:(NSDictionary *)userInfo application:(UIApplication *)app {
  [self showAlert:[NSString stringWithFormat:@"didReceiveRemoteNotif%@", userInfo]];
}

- (void) sendUserTags:( NSDictionary *)tags {
  [self showAlert:[NSString stringWithFormat:@"tags: %@", tags]];
  [OneSignal sendTags: tags];
  NSLog(@"tags: %@", tags);
}
@end
