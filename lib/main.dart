import 'dart:convert';
import './models/CountData.dart';
import 'package:bg_service/widgets/timer/timer.dart';
import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:developer';

import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(MyApp());
}

// this will be used as notification channel id
const notificationChannelId = 'my_foreground';

// this will be used for notification id, So you can update your custom notification with this id.
const notificationId = 888;

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

  service.on('getTimerData').listen((event) {
    //print()
  });

  // bring to foreground
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    final pref = await SharedPreferences.getInstance();
    await pref.reload();
    final String? timeData = pref.getString('timersData');
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        flutterLocalNotificationsPlugin.show(
          notificationId,
          'COOL SERVICE: $timeData',
          'Awesome ',
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
    service.invoke('update', {"counter": 'Heloo'});
  });
}

final service = FlutterBackgroundService();
List<countData> nameCounter = [];

recieveDataFromTimer(int counter, String name) async {
  final pref = await SharedPreferences.getInstance();
  var payload = countData(name, counter);

  var seen = Set<String>();

  nameCounter.add(payload);
  List<countData> unique =
      nameCounter.where((element) => seen.add(element.name)).toList();

  //print(unique.length);
  unique.asMap().forEach((key, value) {
    if (value.name == payload.name) {
      unique[key].name = payload.name;
      unique[key].count = payload.count;
    }
  });

  String enconde = jsonEncode(unique);
  print(enconde);
  await pref.setString('timersData', enconde);
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
  Function(String)? getTimersData;

  List<TimerLess> myTimers = [
    TimerLess(tick: service, sendData: recieveDataFromTimer, timerName: 1),
    TimerLess(tick: service, sendData: recieveDataFromTimer, timerName: 2),
    TimerLess(tick: service, sendData: recieveDataFromTimer, timerName: 3),
    TimerLess(tick: service, sendData: recieveDataFromTimer, timerName: 4),
  ];

  getTimerData(String name) {}

  @override
  void initState() {
    super.initState();
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

  addTimer() {}

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = FlutterBackgroundService();

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Timers'),
      ),
      body: Column(children: <Widget>[
        Expanded(
            child: ListView.builder(
                itemCount: myTimers.length,
                itemBuilder: (context, index) {
                  return myTimers[index];
                })),
        InkWell(
          onTap: () {
            myTimers.add(TimerLess(
                tick: service,
                sendData: recieveDataFromTimer,
                timerName: myTimers.length + 1));
            setState(() {});
          },
          child: Text(
            'Añadir',
            style: TextStyle(color: Colors.amber),
          ),
        )
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: (() {
          stopTimer();
        }),
        child: const Icon(Icons.stop_circle),
      ),
    );
  }
}
