import 'dart:async';

import 'package:background_fetch/background_fetch.dart';
import 'package:device_preview/device_preview.dart' as devicePreview;
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pikobar_flutter/constants/Dictionary.dart';
import 'package:pikobar_flutter/constants/FontsFamily.dart';
import 'package:pikobar_flutter/constants/Navigation.dart';
import 'package:pikobar_flutter/screens/checkDistribution/checkDistributionServices.dart';
import 'package:pikobar_flutter/screens/home/IndexScreen.dart';
import 'package:pikobar_flutter/constants/Colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/DialogRequestPermission.dart';
import 'configs/Routes.dart';
import 'environment/Environment.dart';

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

  Geolocator geolocator = Geolocator();
  Position location;

//  GeolocationStatus geolocationStatus  = await geolocator.checkGeolocationPermissionStatus();

  try{
    location = await geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high, locationPermissionLevel: GeolocationPermission.locationAlways);
    if (location != null && location.latitude != null) {
      print('cekkk geolocation status '+location.latitude.toString());
    }
  }catch(e){
    print("[Background Headless] Location error: $e");
  }


//  Position position = await Geolocator().getLastKnownPosition(desiredAccuracy: LocationAccuracy.high);
//  if (position != null && position.latitude != null) {
//    print('cekk lat long headless'+position.latitude.toString());
//  }else{
//    print('cekk lat long kosong headless');
//  }

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
    enableLocationServices(context);
  }

    Future<void> enableLocationServices(BuildContext context) async {
      PermissionStatus permission = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.location);
      if (permission == PermissionStatus.granted) {
      } else {
        showDialog(
            context: context,
            builder: (BuildContext context) => DialogRequestPermission(
              image: Image.asset(
                '${Environment.iconAssets}map_pin.png',
                fit: BoxFit.contain,
                color: Colors.white,
              ),
              description: Dictionary.permissionLocationSpread,
              onOkPressed: () {
                Navigator.of(context).pop();
                PermissionHandler().requestPermissions(
                    [PermissionGroup.location]).then((status) {
                  _onStatusRequested(context, status);
                });
              },
              onCancelPressed: () {
                // AnalyticsHelper.setLogEvent(Analytics.permissionDismissLocation);
                Navigator.of(context).pop();
              },
            ));
      }
    }


  void _onStatusRequested(BuildContext context,
      Map<PermissionGroup, PermissionStatus> statuses) async {
    final statusLocation = statuses[PermissionGroup.location];
    if (statusLocation == PermissionStatus.granted) {
      enableLocationServices(context);
      // AnalyticsHelper.setLogEvent(Analytics.permissionGrantedLocation);
    } else {
      // AnalyticsHelper.setLogEvent(Analytics.permissionDeniedLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: ColorBase.green));
    CheckDistributions().handleLocation(context);

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

      Geolocator geolocator = Geolocator()..forceAndroidLocationManager = true;
      GeolocationStatus geolocationStatus  = await geolocator.checkGeolocationPermissionStatus();

      print('cekkk geolocation status '+geolocationStatus.toString());

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
}
