import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:developer';

import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(MyApp());
}

// this will be used as notification channel id
const notificationChannelId = 'my_foreground';

// this will be used for notification id, So you can update your custom notification with this id.
const notificationId = 888;
int counter = 0;

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId, // id
    'MY FOREGROUND SERVICE', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.low, // importance must be at low or higher level
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: false,
      isForegroundMode: true,

      notificationChannelId:
          notificationChannelId, // this must match with notification channel you created above.
      initialNotificationTitle: 'AWESOME SERVICE',
      initialNotificationContent: 'Initializing',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: null,
    ),
  );
}

Future<void> onStart(ServiceInstance service) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // bring to foreground
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        counter++;
        flutterLocalNotificationsPlugin.show(
          notificationId,
          'COOL SERVICE',
          'Awesome ${counter}',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId,
              'MY FOREGROUND SERVICE',
              icon: 'ic_bg_service_small',
              ongoing: true,
            ),
          ),
        );
      }
    }
    service.invoke('update', {"counter": counter});
  });
}

/// This is the main application widget.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timeless',
      theme: ThemeData(primarySwatch: Colors.amber),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int counter = 0;
  bool timerActive = false;
  late StreamSubscription streamSubscription;

  @override
  void initState() {
    super.initState();
    final service = FlutterBackgroundService();
    service.on('update').listen((event) {
      if (timerActive == true) {
        setState(() => counter++);
      }
    });
  }

  void startTimer() {
    final service = FlutterBackgroundService();
    service.startService();
  }

  stopTimer() async {
    log('service stopped');
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke("stopService");
    } else {
      service.startService();
    }

    setState(() {});
  }

  String timerPretty(int count) {
    var minutes = (count / 60).floor();
    var seconds = (count % 60);
    if (seconds < 10) {
      return '$minutes : 0$seconds';
    }
    return '$minutes : $seconds';
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Timers'),
      ),
      body: Column(
        children: [
          Center(
              child: Text(timerPretty(counter),
                  style: const TextStyle(color: Colors.amber, fontSize: 50))),
          !timerActive
              ? TextButton(
                  onPressed: () {
                    setState(() {
                      timerActive = !timerActive;
                    });
                  },
                  child: const Icon(
                    Icons.play_circle_outline_outlined,
                    size: 30,
                  ))
              : TextButton(
                  onPressed: () {
                    setState(() {
                      timerActive = !timerActive;
                    });
                  },
                  child: const Icon(
                    Icons.pause_circle,
                    size: 30,
                  )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: stopTimer,
        child: const Icon(Icons.stop_circle),
      ),
    );
  }
}
