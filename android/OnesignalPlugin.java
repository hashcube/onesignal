package com.tealeaf.plugin.plugins;

import com.tealeaf.EventQueue;
import com.tealeaf.plugin.IPlugin;
import com.tealeaf.logger;

import java.util.Date;

import org.json.JSONObject;
import org.json.JSONException;

import android.content.Intent;
import android.app.Activity;
import android.content.Context;
import android.os.Bundle;

import android.content.pm.PackageManager;
import android.content.pm.ApplicationInfo;

import com.onesignal.OneSignal;
import com.onesignal.OneSignal.*;
import com.onesignal.OSNotification;
import com.onesignal.OSNotificationPayload;
import com.onesignal.OSNotificationOpenResult;
import com.onesignal.shortcutbadger.ShortcutBadger;

public class OnesignalPlugin implements IPlugin {

  private static final String TAG = "{{OnesignalPlugin}}";
  private static boolean onesignal = false;

  public class onesignalNotificationReceived extends com.tealeaf.event.Event {
    boolean failed;
    String notification_data;

    public onesignalNotificationReceived(String notification_data) {
      super("onesignalNotificationReceived");
      this.failed = false;
      this.notification_data = notification_data;
    }
  }

  public class onesignalNotificationOpened extends com.tealeaf.event.Event {
    String notification_data;

    public onesignalNotificationOpened(String notification_data) {
      super("onesignalNotificationOpened");
      this.notification_data = notification_data;
    }
  }

  public void onCreateApplication(Context applicationContext) {
  }

  public void onCreate(Activity activity, Bundle savedInstanceState) {
    String g_Project_Number = null, appID = null;
    PackageManager manager = activity.getPackageManager();

    try {
      if (onesignal == false) {
        OneSignal.startInit(activity)
          .inFocusDisplaying(OneSignal.OSInFocusDisplayOption.Notification)
          .unsubscribeWhenNotificationsAreDisabled(true)
          .init();
        ShortcutBadger.applyCount(activity, 0);
        onesignal = true;
        logger.log(TAG, "Onesignal instance created with version", OneSignal.VERSION);
      }
    }
    catch (Exception e) {
      logger.log(TAG, "Onesignal initialization failing", OneSignal.VERSION);
      e.printStackTrace();
    }
  }

  @Override
  public void onPause() {
  }

  public void onRenderPause() {
  }

  @Override
  public void onResume() {
  }

  public void onRenderResume() {
  }

  public void sendUserTags(String jsonData) {
    try {
      JSONObject object = new JSONObject(jsonData);
      sendTags(object);
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  //Send tags to onesignal
  public void sendTags(JSONObject jsonData) {
    try {
      logger.log(TAG, "Send Tags : " , jsonData.toString());
      OneSignal.sendTags(jsonData);
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  //Get notification_received_count, Other tags can be gotten in the same way
  public void getNotificationReceivedCount(final Integer receivedCount) {
    try {
      OneSignal.getTags(new GetTagsHandler() {
        @Override
        public void tagsAvailable(JSONObject rTags) {
          Integer tag_val = 0;
          JSONObject object = new JSONObject();

          logger.log(TAG, "retrieved data for receive : ");
          try {
            tag_val = rTags.getInt("notification_received_count");
          } catch (JSONException eJ){
            logger.log(TAG, "Receiving notification for the first time");
          } catch (Exception e) {
             e.printStackTrace();
          }

          try {
            tag_val += receivedCount ;
            object.put("notification_received_count",
                             tag_val.toString());
            sendTags(object);
          } catch (JSONException eJ){
            logger.log(TAG, "error in json");
          }
        }
      });
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

  public void onStart() {
  }

  public void onFirstRun() {
  }

  public void onStop() {
  }

  public void onDestroy() {
  }

  public void onNewIntent(Intent intent) {
  }

  public void setInstallReferrer(String referrer) {
  }

  public void onActivityResult(Integer request, Integer result, Intent data) {
  }

  public boolean consumeOnBackPressed() {
    return true;
  }

  public void onBackPressed() {
  }

  public class OpenedHandler implements NotificationOpenedHandler {
    @Override
    public void notificationOpened (OSNotificationOpenResult openedResult) {
      logger.log(TAG, "Notification opened");
      OSNotification notification = openedResult.notification;
      JSONObject os_data = NotificationData.get(openedResult.notification);
      EventQueue.pushEvent(new onesignalNotificationOpened(os_data.toString()));
      //TODO: Actions(When button is clicked)
    }
  }

  public class ReceivedHandler implements NotificationReceivedHandler {
    @Override
    public void notificationReceived(OSNotification notification) {
      logger.log(TAG, "Notification received");
      JSONObject os_data = NotificationData.get(notification);
      EventQueue.pushEvent(new onesignalNotificationReceived(os_data.toString()));
    }
  }

  public static class NotificationData {
    public static JSONObject get(OSNotification notification) {
      JSONObject os_data = new JSONObject();
      OSNotificationPayload payload = notification.payload;
      JSONObject additional_data;

      try {
        os_data.put("notification_id", payload.notificationID);
        os_data.put("is_foreground", notification.isAppInFocus);
        os_data.put("title", payload.title);
        os_data.put("body", payload.body);
        additional_data = payload.additionalData;
        if (additional_data != null) {
          os_data.put("additional_data", additional_data.toString());
        }
        os_data.put("launch_url", payload.launchURL);
      } catch (JSONException e) {
        e.printStackTrace();
      }
      //TODO: More properties can be sent to the client

      return os_data;
    }
  }
}
