import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:bg_service/main.dart';

import '../../models/CountData.dart';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:numberpicker/numberpicker.dart';

import 'package:shared_preferences/shared_preferences.dart';

class TimerLess extends StatefulWidget {
  TimerLess(
      {super.key,
      required this.tick,
      this.timerName = 1,
      required this.stopMusic});

  final FlutterBackgroundService tick;
  int timerName = 1;
  VoidCallback stopMusic;

  @override
  State<TimerLess> createState() => _TimerState();
}

class _TimerState extends State<TimerLess> with TickerProviderStateMixin {
  int counter = 0;
  bool timerActive = false;
  bool timeEnd = false;
  int valueToPick = 15;
  int valueToReach = 0;
  bool isEndTimer = false;
  late Timer timer;

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String timerData = '';
  late String name;
  List<CountData> myTimerPersisnt = [];
  late AnimationController _animationController;

  CountData getJsonTimer(Map<String, dynamic> data) {
    var myTimer = CountData('', 0, false, false);
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
      "timeEnd": timeEnd,
    };
    service.invoke("getTimer", timerData);
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )
      ..forward()
      ..addListener(() {
        if (_animationController.isCompleted) {
          _animationController.repeat();
        }
      });

    name = 'PC:${widget.timerName}';

    widget.tick.on('update').listen((event) async {
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
              timeEnd = true;
            });
            startTimer();
          }
        }
      }
    });
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
        Padding(
          padding: const EdgeInsets.all(3),
          child: Container(
            height: 100,
            color: Colors.grey[800],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: InkWell(
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
                                        textStyle:
                                            TextStyle(color: Colors.amber[200]),
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
                                            style:
                                                TextStyle(color: Colors.black),
                                          )),
                                    ],
                                  ),
                                );
                              }),
                            );
                          });
                    },
                    child: Text(timerPretty(counter),
                        style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.w500,
                            fontSize: 60)),
                  ),
                ),
                // ignore: prefer_const_constructors

                timeEnd ? stopButton() : Container(),

                Align(
                  child: playSwitch(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget stopButton() {
    return InkWell(
      onTap: stopMusic,
      child: AnimatedIcon(
          size: 40,
          color: Colors.amber,
          icon: AnimatedIcons.play_pause,
          progress: _animationController),
    );
  }

  Widget playSwitch() {
    return Switch(
      // This bool value toggles the switch.
      value: timerActive,
      activeColor: Colors.amber,
      onChanged: (bool value) {
        setState(() {
          if (counter <= 0) {
            timeEnd = !value;
          }
          timerActive = value;
        });
        startTimer();
      },
    );
  }

  void stopMusic() {
    service.invoke("stopMusic");
  }
}
