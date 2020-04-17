import 'dart:convert';
import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:bottom_navigation_badge/bottom_navigation_badge.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pikobar_flutter/components/DialogUpdateApp.dart';
import 'package:pikobar_flutter/constants/Analytics.dart';
import 'package:pikobar_flutter/constants/Dictionary.dart';
import 'package:pikobar_flutter/constants/NewsType.dart';
import 'package:pikobar_flutter/constants/firebaseConfig.dart';
import 'package:pikobar_flutter/environment/Environment.dart';
import 'package:pikobar_flutter/repositories/AuthRepository.dart';
import 'package:pikobar_flutter/repositories/MessageRepository.dart';
import 'package:pikobar_flutter/screens/faq/FaqScreen.dart';
import 'package:pikobar_flutter/screens/home/BackgroundServicePikobar.dart';
import 'package:pikobar_flutter/screens/home/components/HomeScreen.dart';
import 'package:pikobar_flutter/screens/messages/messages.dart';
import 'package:pikobar_flutter/screens/messages/messagesDetailSecreen.dart';
import 'package:pikobar_flutter/screens/myAccount/ProfileScreen.dart';
import 'package:pikobar_flutter/screens/news/News.dart';
import 'package:pikobar_flutter/screens/news/NewsDetailScreen.dart';
import 'package:pikobar_flutter/utilities/AnalyticsHelper.dart';
import 'package:pikobar_flutter/utilities/AnnouncementSharedPreference.dart';
import 'package:pikobar_flutter/utilities/NotificationHelper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IndexScreen extends StatefulWidget {
  @override
  IndexScreenState createState() => IndexScreenState();
}

class IndexScreenState extends State<IndexScreen> {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  static FirebaseInAppMessaging firebaseInAppMsg = FirebaseInAppMessaging();

  int _currentIndex = 0;

  BottomNavigationBadge badger;
  List<BottomNavigationBarItem> items;
  int countMessage = 0;

  //variabel used for background fetch
  bool _enabled = true;
  int _status = 0;
  List<String> _events = [];

  @override
  void initState() {
    initializeDateFormatting();
    getCountMessage();
    createDirectory();
    setFlutterDownloaderInitial();
    BackgroundServicePikobar.registerHeadless();

    _initializeBottomNavigationBar();
    setStatAnnouncement();
    registerFCMToken();

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        NotificationHelper().showNotification(
            message['notification']['title'], message['notification']['body'],
            payload: jsonEncode(message['data']),
            onSelectNotification: onSelectNotification);
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        _actionNotification(jsonEncode(message['data']));
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        _actionNotification(jsonEncode(message['data']));
      },
    );

//    _firebaseMessaging.getToken().then((token) => print(token));

    _firebaseMessaging.subscribeToTopic('general');

    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(sound: true, badge: true, alert: true));

    firebaseInAppMsg.setAutomaticDataCollectionEnabled(true);

    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // Load persisted fetch events from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String json = prefs.getString(EVENTS_KEY);
    if (json != null) {
      setState(() {
        _events = jsonDecode(json).cast<String>();
      });
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
      setState(() {
        _status = status;
      });
    }).catchError((e) {
      print('[BackgroundFetch] configure ERROR: $e');
      setState(() {
        _status = e;
      });
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
    setState(() {
      _status = status;
    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  void _onBackgroundFetch(String taskId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime timestamp = new DateTime.now();
    // This is the fetch-event callback.
    print("[BackgroundFetch] Event received: $taskId");
    setState(() {
      _events.insert(0, "$taskId@${timestamp.toString()}");
    });
    // Persist fetch events in SharedPreferences
    prefs.setString(EVENTS_KEY, jsonEncode(_events));

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
    setState(() {
      _enabled = enabled;
    });
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
    setState(() {
      _status = status;
    });
  }

  void _onClickClear() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove(EVENTS_KEY);
    setState(() {
      _events = [];
    });
  }

  setStatAnnouncement() async {
    await AnnouncementSharedPreference.setAnnounceScreen(true);
  }

  setFlutterDownloaderInitial() async {
    await FlutterDownloader.initialize();
  }

  createDirectory() async {
    if (Platform.isAndroid) {
      String localPath =
          (await getExternalStorageDirectory()).path + '/download';
      final publicDownloadDir = Directory(Environment.downloadStorage);
      final savedDir = Directory(localPath);
      bool hasExistedPublicDownloadDir = await publicDownloadDir.exists();
      bool hasExistedSavedDir = await savedDir.exists();
      if (!hasExistedPublicDownloadDir) {
        publicDownloadDir.create();
      }
      if (!hasExistedSavedDir) {
        savedDir.create();
      }
    }
  }

  registerFCMToken() async {
    await AuthRepository().registerFCMToken();
  }

  _initializeBottomNavigationBar() {
    badger = BottomNavigationBadge(
        backgroundColor: Colors.red,
        badgeShape: BottomNavigationBadgeShape.circle,
        textColor: Colors.white,
        position: BottomNavigationBadgePosition.topRight,
        textSize: 8);

    items = [
      BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.home, size: 16),
          title: Column(
            children: <Widget>[
              SizedBox(height: 4),
              Text(Dictionary.home),
            ],
          )),
      BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.solidEnvelope, size: 16),
          title: Column(
            children: <Widget>[
              SizedBox(height: 4),
              Text(Dictionary.message),
            ],
          )),
      BottomNavigationBarItem(
          icon: Icon(FontAwesomeIcons.solidQuestionCircle, size: 16),
          title: Column(
            children: <Widget>[
              SizedBox(height: 4),
              Text(Dictionary.help),
            ],
          )),
      BottomNavigationBarItem(
          icon: Icon(Icons.person),
          title: Column(
            children: <Widget>[
              Text(Dictionary.profile),
            ],
          )),
    ];
  }

  Future<void> onSelectNotification(String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);

      _actionNotification(payload);
    }
  }

  _actionNotification(String payload) {
    final data = jsonDecode(payload);
    if (data['target'] == 'news') {
      String newsType;

      switch (data['type']) {
        case NewsType.articles:
          newsType = Dictionary.latestNews;
          break;

        case NewsType.articlesNational:
          newsType = Dictionary.nationalNews;
          break;

        case NewsType.articlesWorld:
          newsType = Dictionary.worldNews;
          break;

        default:
          newsType = Dictionary.latestNews;
      }

      if (data['id'] != null && data['id'] != 'null') {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => NewsDetailScreen(
                  id: data['id'],
                  news: newsType,
                  isFromNotification: true,
                )));
      } else {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => News(news: newsType)));
      }
    } else if (data['target'] == 'broadcast') {
      if (data['id'] != null && data['id'] != 'null') {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => MessageDetailScreen(
                  id: data['id'],
                  isFromNotification: true,
                )));
      } else {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => Messages(indexScreenState: this)));
      }
    }
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildMainScaffold(context);
  }

  _buildMainScaffold(BuildContext context) {
    return Scaffold(
      body: _buildContent(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
          onTap: onTabTapped,
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          items: items),
    );
  }

  getCountMessage() {
    Future.delayed(Duration(milliseconds: 0), () async {
      countMessage = await MessageRepository().hasUnreadData();
      setState(() {
        // ignore: unnecessary_statements
        if (countMessage <= 0) {
          items[1] = BottomNavigationBarItem(
              icon: Icon(FontAwesomeIcons.solidEnvelope, size: 16),
              title: Column(
                children: <Widget>[
                  SizedBox(height: 4),
                  Text(Dictionary.message),
                ],
              ));
        } else {
          items = badger.setBadge(items, countMessage.toString(), 1);
        }
      });
    });
  }

  Widget _buildContent(int index) {
    switch (index) {
      case 0:
        return HomeScreen();
      case 1:
        AnalyticsHelper.setLogEvent(Analytics.tappedMessage);
        return Messages(indexScreenState: this);

      case 2:
        AnalyticsHelper.setLogEvent(Analytics.tappedFaq);
        return FaqScreen();

      case 3:
        return ProfileScreen();
      default:
        return HomeScreen();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
