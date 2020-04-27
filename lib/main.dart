import 'dart:async';

import 'package:background_fetch/background_fetch.dart';
import 'package:device_preview/device_preview.dart' as devicePreview;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_location/flutter_background_location.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pikobar_flutter/constants/Dictionary.dart';
import 'package:pikobar_flutter/constants/FontsFamily.dart';
import 'package:pikobar_flutter/constants/Navigation.dart';
import 'package:pikobar_flutter/screens/home/IndexScreen.dart';
import 'package:pikobar_flutter/constants/Colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'configs/Routes.dart';

class SimpleBlocDelegate extends BlocDelegate {
  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    print(transition);
  }

  @override
  void onError(Bloc bloc, Object error, StackTrace stacktrace) {
    super.onError(bloc, error, stacktrace);
    print(error);
  }
}

/// This "Headless Task" is run when app is terminated.
void backgroundFetchHeadlessTask(String taskId) async {
  print("[BackgroundFetch] Headless event received: $taskId");
  DateTime timestamp = DateTime.now();
  String saveData = timestamp.toString();

  print('Simpan Data cek waktunya headless : ' + saveData.toString());


  // Persist fetch events in SharedPreferences
//  prefs.setString(EVENTS_KEY, saveData);

//  if (taskId == 'flutter_background_fetch') {
//    BackgroundFetch.scheduleTask(
//      TaskConfig(
//          taskId: "com.transistorsoft.customtask",
//          delay: 5000,
//          periodic: false,
//          forceAlarmManager: true,
//          stopOnTerminate: false,
//          enableHeadless: true),
//    );
//  }

  BackgroundFetch.finish(taskId);
}

void main() {
  // Set `enableInDevMode` to true to see reports while in debug mode
  // This is only to be used for confirming that reports are being
  // submitted as expected. It is not intended to be used for everyday
  // development.
  // Crashlytics.instance.enableInDevMode = true;

  // Pass all uncaught errors from the framework to Crashlytics.
  FlutterError.onError = Crashlytics.instance.recordFlutterError;

  BlocSupervisor.delegate = SimpleBlocDelegate();

  runZoned<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // runApp(devicePreview.DevicePreview(
    //   enabled: !kReleaseMode, // disabled in release mode
    //   builder: (context) => App(),
    // ));
    runApp(App());
    BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
  }, onError: Crashlytics.instance.recordError);
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  static FirebaseAnalytics analytics = FirebaseAnalytics();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: ColorBase.green));

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      title: '${Dictionary.appName}',
      theme: ThemeData(
          primaryColor: ColorBase.green,
          primaryColorBrightness: Brightness.dark,
          fontFamily: FontsFamily.sourceSansPro),
      debugShowCheckedModeBanner: false,
      home: IndexScreen(),
      onGenerateRoute: generateRoutes,
      navigatorKey: NavigationConstrants.navKey,
    );
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Configure BackgroundFetch.
    BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 15,
            stopOnTerminate: false,
            enableHeadless: true,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.NONE), (String taskId) async {
      // This is the fetch-event callback.
      print("[BackgroundFetch] Event received $taskId");
      DateTime timestamp = DateTime.now();
      String saveData = timestamp.toString();
      print('Simpan Data cek waktunya : ' + saveData.toString());

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
      // IMPORTANT:  You must signal completion of your task or the OS can punish your app
      // for taking too long in the background.
      BackgroundFetch.finish(taskId);
    }).then((int status) {
      print('[BackgroundFetch] configure success: $status');
    }).catchError((e) {
      print('[BackgroundFetch] configure ERROR: $e');
    });

    // Optionally query the current BackgroundFetch status.
    int status = await BackgroundFetch.status;
    print('cekkk status background sekarang? ' + status.toString());
//    setState(() {
//      _status = status;
//    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

//  void _onBackgroundFetch(String taskId) async {
//    SharedPreferences prefs = await SharedPreferences.getInstance();
//    DateTime timestamp = new DateTime.now();
//    var lokasi;
//    // This is the fetch-event callback.
//    print("[BackgroundFetch] Event received: $taskId");
//
////    setState(() {
////      _events.insert(0, "$taskId@${timestamp.toString()}");
////    });
//    // Persist fetch events in SharedPreferences
////     Position position = await Geolocator()
////         .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
////     String saveData = 'lat : '+position.latitude.toString()+', long : '+position.longitude.toString()+', waktu : '+timestamp.toString();
//
//    FlutterBackgroundLocation.startLocationService();
//    FlutterBackgroundLocation.getLocationUpdates((location) {
//      lokasi = location;
////      print(location);
//    });
//    FlutterBackgroundLocation.stopLocationService();
//
//
//    String saveData = timestamp.toString();
//
//    print('cekk isi location '+lokasi.latitude.toString());
//
////     print('Simpan Data '+saveData+', cek waktunya : '+timestamp.toString());
//    print('Simpan Data cek waktunya : '+timestamp.toString());
//
//    prefs.setString(Dictionary.eventKey, saveData);
//
//    if (taskId == "flutter_background_fetch") {
//      // Schedule a one-shot task when fetch event received (for testing).
//      BackgroundFetch.scheduleTask(TaskConfig(
//          taskId: "com.transistorsoft.customtask",
//          delay: 5000,
//          periodic: false,
//          forceAlarmManager: true,
//          stopOnTerminate: false,
//          enableHeadless: true));
//    }
//
//    // IMPORTANT:  You must signal completion of your fetch task or the OS can punish your app
//    // for taking too long in the background.
//    BackgroundFetch.finish(taskId);
//  }

}
