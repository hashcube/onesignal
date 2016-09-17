/* jshint ignore:start */
import util.underscore as _;
/* jshint ignore:end */
function pluginSend(evt, params) {
  NATIVE.plugins.sendEvent('OnesignalPlugin', evt,JSON.stringify(params || {}));
}

function pluginOn(evt, next) {
  NATIVE.events.registerHandler(evt, next);
}

exports = new (Class(function() {

  var cb = null,
    data = {},
    invokeCallback = function () {
      var args = arguments;

      // If callback available,
      if (cb) {
        // Run it
        cb.apply(null, args);
      } else {
        // Store it
        data[args[0]] = args[1];
      }
    };

  NATIVE.events.registerHandler('onesignalNotificationReceived', function(v) {
    var received_data;

    if (!v.failed) {
      received_data = JSON.parse(v.notification_data);
      logger.log("{onesignal} data at js", JSON.stringify(v));
      invokeCallback("NotificationReceived", received_data);
    }
  });

  NATIVE.events.registerHandler('onesignalNotificationOpened', function(v) {
    var received_data;

    received_data = JSON.parse(v.notification_data);
    logger.log("{onesignal} onOpened data at js", JSON.stringify(v));
    invokeCallback("NotificationOpened", received_data);
  });

  // SendTags
  this.sendTags = function (obj) {
    pluginSend('sendUserTags', obj);
  };

  this.registerCallback = function (callback) {

    cb = callback;
    for (var key in data) {
      if (data.hasOwnProperty(key)) {
        invokeCallback(key, data[key]);
        delete data[key];
      }
    }
  };

  this.getNotificationData = function (cb) {
    NATIVE.plugins.sendRequest("OnesignalPlugin", "getNotificationData", {} , function (err, res) {
        if (!err) {
          cb(res);
        }
    });
  };

}))();
