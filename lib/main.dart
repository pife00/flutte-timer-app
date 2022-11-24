import 'dart:convert';
import './models/CountData.dart';
import 'package:bg_service/widgets/timer/timer.dart';
import 'package:flutter/material.dart';

import 'dart:math' as math;
import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'dart:math';
import 'package:responsive_sizer/responsive_sizer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(MyApp());
}

final service = FlutterBackgroundService();
List<CountData> nameCounter = [];
List<CountData> unique = [];
final Iterable<Duration> pauses = [
  const Duration(milliseconds: 500),
  const Duration(milliseconds: 1000),
  const Duration(milliseconds: 500),
  const Duration(milliseconds: 500),
  const Duration(milliseconds: 1000),
  const Duration(milliseconds: 500),
  const Duration(milliseconds: 500),
  const Duration(milliseconds: 1000),
  const Duration(milliseconds: 500),
];
bool _canVibrate = true;
bool isTimersActive = false;
final player = AudioPlayer();

final sounds = [
  'sounds/Cozy.mp3',
  'sounds/Hearthome.mp3',
  'sounds/National.mp3',
];

Future playAudio() async {
  var intValue = Random().nextInt(2);
  String ringTone = sounds[intValue];
  await player.play(AssetSource(ringTone));
}

Future stopAudio() async {
  await player.stop();
}

onVibration() async {
  if (_canVibrate) {
    await Vibrate.vibrateWithPauses(pauses);
  }
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
      autoStart: true,
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

String timerPretty(int count) {
  var minutes = (count / 60).floor();
  var seconds = (count % 60);
  var m = '$minutes';
  var s = '$seconds';
  if (minutes < 10) {
    m = '0$minutes';
  }
  if (seconds < 10) {
    s = '0$seconds';
  }
  return '$m : $s';
}

Future<void> onStart(ServiceInstance service) async {
  BuildContext context;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<CountData> payload = [];

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  service.on('stopMusic').listen((event) async {
    await stopAudio();
  });

  service.on('getTimer').listen((event) async {
    String? name = event?['name'];
    int? counter = event?['counter'];
    bool? status = event?['status'];
    bool? timeEnd = event?['timeEnd'];
    var payload = CountData(name!, counter!, status!, timeEnd!);
    var seen = Set<String>();
    nameCounter.add(payload);

    //Orden
    unique = nameCounter.where((element) => seen.add(element.name)).toList();

    //No repeat
    unique.asMap().forEach((key, value) {
      if (value.name == payload.name) {
        unique[key].name = payload.name;
        unique[key].count = payload.count;
        unique[key].status = payload.status;
        unique[key].timeEnd = payload.timeEnd;
      }
    });
  });

  // bring to foreground
  Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
    String message = "";

    for (var element in unique) {
      if (element.count > 0 && element.status == true) {
        element.count--;
        message = '$message${element.name} ${timerPretty(element.count)}\n';

        if (element.count == 0) {
          await playAudio();
          await onVibration();
        }
      }
    }

    //int? count = payload.count;
    // print(date);
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        flutterLocalNotificationsPlugin.show(
          notificationId,
          'Timers',
          message,
          const NotificationDetails(
            android: AndroidNotificationDetails(
                notificationChannelId, 'MY FOREGROUND SERVICE',
                icon: 'ic_bg_service_small',
                ongoing: true,
                styleInformation: BigTextStyleInformation('')),
          ),
        );
      }
    }

    if (unique.isEmpty) {
      String enconde = jsonEncode(unique);
      service.invoke('update', {"data": enconde});
    } else {
      String enconde = jsonEncode(unique);
      service.invoke('update', {"data": enconde});
    }

    shouldOffService(unique);
    service.invoke('isTimersUpdate', {"data": isTimersActive});
  });
}

shouldOffService(List<CountData> unique) {
  if (unique.isEmpty) {}

  if (unique.isNotEmpty) {
    for (var element in unique) {
      if (element.count > 0) {
        isTimersActive = true;
      } else {
        isTimersActive = false;
      }
    }
  }
}

/// This is the main application widget.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(builder: (context, orientation, screenTyoe) {
      return MaterialApp(
        title: 'Timeless',
        theme: ThemeData(primarySwatch: Colors.amber),
        home: HomePage(),
      );
    });
  }
}

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  Function(String)? getTimersData;
  int counter = 0;
  bool isServiceActive = true;
  List<int> myTimers = [1, 2, 3, 4, 5];
  Color colorBg = const Color.fromRGBO(33, 33, 33, 1);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    final isbackground = state == AppLifecycleState.paused;
    final isClose = state == AppLifecycleState.detached;

    if (isbackground) {}

    if (isClose) {
      if (isTimersActive == false) {
        service.invoke('stopService');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    service.on('isTimersUpdate').listen((event) {
      isTimersActive = event!["data"];
    });
  }

  void startTimer() {
    final service = FlutterBackgroundService();
    service.startService();
  }

  stopService() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke("stopService");

      isServiceActive = false;
    } else {
      service.startService();

      isServiceActive = true;
    }
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = FlutterBackgroundService();

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              'Timers',
              style: TextStyle(
                  color: isServiceActive ? Colors.amber : Colors.grey),
            ),
            Switch(
                value: isServiceActive,
                activeColor: Colors.amber,
                inactiveThumbColor: Colors.grey[700],
                onChanged: ((value) {
                  setState(() {
                    isServiceActive = value;
                  });
                  stopService();
                }))
          ],
        ),
      ),
      body: Column(children: <Widget>[
        Expanded(
            child: ReorderableListView(
          onReorder: ((oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }

              final myTimer = myTimers.removeAt(oldIndex);
              myTimers.insert(newIndex, myTimer);
            });
          }),
          children: <Widget>[
            for (int index in myTimers)
              Container(
                color: colorBg,
                key: ValueKey('$index'),
                child: ListTile(
                  title: TimerLess(tick: service, timerName: index),
                  onTap: (() {}),
                ),
              )
          ],
        )),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: null,
        child: InkWell(
          onTap: () async {
            myTimers.add(myTimers.length + 1);
            setState(() {});
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
