import 'dart:convert';

import 'package:background_fetch/background_fetch.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundServicePikobar {
  static const EVENTS_KEY = "fetch_events";

  /// This "Headless Task" is run when app is terminated.
   void backgroundFetchHeadlessTask(String taskId) async {
    print("[BackgroundFetch] Headless event received: $taskId");
    DateTime timestamp = DateTime.now();

    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Read fetch_events from SharedPreferences
    List<String> events = [];
    String json = prefs.getString(EVENTS_KEY);
    if (json != null) {
      events = jsonDecode(json).cast<String>();
    }
    // Add new event.
    events.insert(0, "$taskId@$timestamp [Headless]");
    // Persist fetch events in SharedPreferences
    prefs.setString(EVENTS_KEY, jsonEncode(events));

    BackgroundFetch.finish(taskId);

    if (taskId == 'flutter_background_fetch') {
      BackgroundFetch.scheduleTask(TaskConfig(
          taskId: "com.transistorsoft.customtask",
          delay: 5000,
          periodic: false,
          forceAlarmManager: true,
          stopOnTerminate: false,
          enableHeadless: true));
    }
  }

//   void registerHeadless() {
//    BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
//    initPlatformState();
//  }

  // Platform messages are asynchronous, so we initialize in an async method.
   Future<void> initPlatformState() async {
    // Load persisted fetch events from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String json = prefs.getString(EVENTS_KEY);


    if (json != null) {
      print('cekk isinya ' + json);
//      setState(() {
//        _events = jsonDecode(json).cast<String>();
//      });
    }

    // Configure BackgroundFetch.
    BackgroundFetch.configure(
            BackgroundFetchConfig(
              minimumFetchInterval: 15,
              forceAlarmManager: false,
              stopOnTerminate: false,
              startOnBoot: true,
              enableHeadless: true,
              requiresBatteryNotLow: false,
              requiresCharging: false,
              requiresStorageNotLow: false,
              requiresDeviceIdle: false,
              requiredNetworkType: NetworkType.NONE,
            ),
            _onBackgroundFetch)
        .then((int status) {
      print('[BackgroundFetch] configure success: $status');
//      setState(() {
//        _status = status;
//      });
    }).catchError((e) {
      print('[BackgroundFetch] configure ERROR: $e');
//      setState(() {
//        _status = e;
//      });
    });

    // Schedule a "one-shot" custom-task in 10000ms.
    // These are fairly reliable on Android (particularly with forceAlarmManager) but not iOS,
    // where device must be powered (and delay will be throttled by the OS).
    BackgroundFetch.scheduleTask(TaskConfig(
        taskId: "com.transistorsoft.customtask",
        delay: 10000,
        periodic: false,
        forceAlarmManager: true,
        stopOnTerminate: false,
        enableHeadless: true));

    // Optionally query the current BackgroundFetch status.
    int status = await BackgroundFetch.status;
    print('cekk status bos ' + status.toString());
//    setState(() {
//      _status = status;
//    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
//    if (!mounted) return;
  }

   void _onBackgroundFetch(String taskId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime timestamp = new DateTime.now();
    // This is the fetch-event callback.
    print("[BackgroundFetch] Event received: $taskId");
//    setState(() {
//      _events.insert(0, "$taskId@${timestamp.toString()}");
//    });
    // Persist fetch events in SharedPreferences
     String cek = 'lat long simpann';

    prefs.setString(EVENTS_KEY, cek);


    print('cekk isinyya '+cek+', cek waktunya : '+timestamp.toString());

    if (taskId == "flutter_background_fetch") {
      // Schedule a one-shot task when fetch event received (for testing).
      BackgroundFetch.scheduleTask(TaskConfig(
          taskId: "com.transistorsoft.customtask",
          delay: 5000,
          periodic: false,
          forceAlarmManager: true,
          stopOnTerminate: false,
          enableHeadless: true));
    }

    // IMPORTANT:  You must signal completion of your fetch task or the OS can punish your app
    // for taking too long in the background.
    BackgroundFetch.finish(taskId);
  }

   void _onClickEnable(enabled) {
//    setState(() {
//      _enabled = enabled;
//    });
    if (enabled) {
      BackgroundFetch.start().then((int status) {
        print('[BackgroundFetch] start success: $status');
      }).catchError((e) {
        print('[BackgroundFetch] start FAILURE: $e');
      });
    } else {
      BackgroundFetch.stop().then((int status) {
        print('[BackgroundFetch] stop success: $status');
      });
    }
  }

   void _onClickStatus() async {
    int status = await BackgroundFetch.status;
    print('[BackgroundFetch] status: $status');
//    setState(() {
//      _status = status;
//    });
  }

   void _onClickClear() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(EVENTS_KEY);
//    setState(() {
//      _events = [];
//    });
  }
}
