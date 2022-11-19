import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:bg_service/main.dart';

import '../../models/CountData.dart';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

final player = AudioPlayer();

class TimerLess extends StatefulWidget {
  TimerLess({
    super.key,
    required this.tick,
    this.timerName = 1,
  });

  final FlutterBackgroundService tick;
  int timerName = 1;

  @override
  State<TimerLess> createState() => _TimerState();
}

class _TimerState extends State<TimerLess> {
  final bool _canVibrate = true;
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
  int counter = 0;
  bool timerActive = false;
  int valueToPick = 15;
  int valueToReach = 0;
  bool isEndTimer = false;
  late Timer timer;

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String timerData = '';
  late String name;
  List<CountData> myTimerPersisnt = [];

  CountData getJsonTimer(Map<String, dynamic> data) {
    var myTimer = CountData('', 0, false);
    if (data['data'].isEmpty) {
      log('${data['data']}');
      return myTimer;
    } else {
      List<dynamic> json = jsonDecode(data['data']);
      json.forEach((element) => {
            if (CountData.fromJson(element).name == name)
              {
                myTimer.name = CountData.fromJson(element).name,
                myTimer.count = CountData.fromJson(element).count,
                myTimer.status = CountData.fromJson(element).status,
              }
          });
      //log('${myTimer.name}');
      return myTimer;
    }
  }

  isTimerPending() async {
    widget.tick.on('update').listen((event) async {
      timerActive = await event!['status'];
    });
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

  startTimer() async {
    Map<String, dynamic> timerData = {
      "name": name,
      "counter": counter,
      "status": timerActive,
    };
    service.invoke("getTimer", timerData);
  }

  Future playAudio() async {
    await player.play(AssetSource('sounds/Ereve.mp3'));
  }

  Future stopAudio() async {
    await player.stop();
  }

  @override
  void initState() {
    super.initState();
    name = 'PC:${widget.timerName}';
    // isTimerPending();
    //getDataTimer();
    widget.tick.on('update').listen((event) async {
      //isTimerPending();
      CountData myTimer = getJsonTimer(event!);
      int counterEvent = myTimer.count;
      String nameEvent = myTimer.name;
      bool stateEvent = myTimer.status;
      //log('$stateEvent');
      setState(() {
        timerActive = stateEvent;
      });

      if (timerActive) {
        if (nameEvent == name) {
          setState(() {
            counter = counterEvent;
          });

          if (counter <= 0) {
            setState(() {
              timerActive = false;
            });
            startTimer();
            playAudio();
            await onVibration();
            // ignore: use_build_context_synchronously
            _dialogBuilder(context);
          }
        }
      }
    });
  }

  onVibration() async {
    if (_canVibrate) {
      await Vibrate.vibrateWithPauses(pauses);
    }
  }

  handlerCounter() {
    valueToReach = (valueToPick * 60);
    counter = valueToReach;
    valueToPick = 15;
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
            onTap: () {
              showModalBottomSheet<void>(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: ((context, setState) {
                        return Container(
                          color: Colors.grey[800],
                          child: Column(
                            children: <Widget>[
                              NumberPicker(
                                textStyle: TextStyle(color: Colors.amber[200]),
                                value: valueToPick,
                                step: 1,
                                minValue: 0,
                                maxValue: 100,
                                onChanged: (value) {
                                  setState(() {
                                    valueToPick = value;
                                  });
                                },
                              ),
                              TextButton(
                                  style: TextButton.styleFrom(
                                      backgroundColor: Colors.amber),
                                  onPressed: (() {
                                    handlerCounter();
                                    Navigator.pop(context);
                                  }),
                                  child: const Text(
                                    'OK',
                                    style: TextStyle(color: Colors.black),
                                  )),
                            ],
                          ),
                        );
                      }),
                    );
                  });
            },
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                height: 100,
                color: Colors.grey[800],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(timerPretty(counter),
                          style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.w500,
                              fontSize: 60)),
                    ),
                    Align(
                      child: playSwitch(),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget playSwitch() {
    return Switch(
      // This bool value toggles the switch.
      value: timerActive,
      activeColor: Colors.amber,
      onChanged: (bool value) {
        setState(() {
          timerActive = value;
        });
        startTimer();
      },
    );
  }

  Future<void> _dialogBuilder(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Acabo alguien',
            style: TextStyle(color: Colors.amber),
          ),
          content: const Text(
              'Se le termino el tiempo a alguien ni idea busca.',
              style: TextStyle(color: Colors.amber)),
          backgroundColor: Colors.grey[800],
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(backgroundColor: Colors.amber),
              child: const Text(
                'Aceptar',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {
                stopAudio();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
