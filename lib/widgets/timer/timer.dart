import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:bg_service/main.dart';
import 'package:intl/intl.dart';

import '../../models/CountData.dart';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:numberpicker/numberpicker.dart';

import 'package:shared_preferences/shared_preferences.dart';

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

class _TimerState extends State<TimerLess> with TickerProviderStateMixin {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  int counter = 0;
  bool timerActive = false;
  bool timeEnd = false;
  int valueToPick = 15;
  int valueToReach = 0;
  bool isEndTimer = false;
  String timerData = '';
  List<CountData> myTimerPersisnt = [];
  String dateStartTimer = '';
  late Timer timer;
  late String name;
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
    if (counter > 0) {
      var now = DateTime.now();
      var later = now.add(Duration(seconds: counter));
      String formatter = DateFormat('jm').format(later);
      setState(() {
        dateStartTimer = formatter;
      });
    }
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
    log('$name: ${widget.key}');
    widget.tick.on('update').listen((event) async {
      log(name);
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
            height: 120,
            decoration: BoxDecoration(
                color: timerActive
                    ? Color.fromARGB(255, 37, 37, 35)
                    : Colors.grey[900],
                boxShadow: [
                  BoxShadow(
                      color: timerActive
                          ? Colors.amber.withOpacity(0.3)
                          : Colors.black.withOpacity(0.5),
                      spreadRadius: 0.5,
                      blurRadius: 1,
                      offset: Offset(0, 2)),
                ]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: InkWell(
                    onTap: () {
                      showModal(context);
                    },
                    child: Column(children: <Widget>[
                      dateStart(dateStartTimer),
                      showTimer(),
                      pcName(name),
                    ]),
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

  Future<void> showModal(BuildContext context) {
    return showModalBottomSheet<void>(
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
                      maxValue: 180,
                      onChanged: (value) {
                        setState(() {
                          valueToPick = value;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                            style: TextButton.styleFrom(
                                backgroundColor: Colors.amber),
                            onPressed: (() {
                              setState(() {
                                valueToPick = 30;
                              });
                            }),
                            child: const Text(
                              '30',
                              style: TextStyle(color: Colors.black),
                            )),
                        IconButton(
                          icon: const Icon(
                            Icons.remove,
                            color: Colors.amber,
                          ),
                          onPressed: () => setState(() {
                            final newValue = valueToPick - 10;
                            valueToPick = newValue.clamp(0, 100);
                          }),
                        ),
                        Text(
                          'Valor actual: $valueToPick',
                          style: const TextStyle(color: Colors.amber),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.amber),
                          onPressed: () => setState(() {
                            final newValue = valueToPick + 20;
                            valueToPick = newValue.clamp(0, 100);
                          }),
                        ),
                        TextButton(
                            style: TextButton.styleFrom(
                                backgroundColor: Colors.amber),
                            onPressed: (() {
                              setState(() {
                                valueToPick = 60;
                              });
                            }),
                            child: const Text(
                              '60',
                              style: TextStyle(color: Colors.black),
                            )),
                      ],
                    ),
                    TextButton(
                        style:
                            TextButton.styleFrom(backgroundColor: Colors.amber),
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
  }

  Widget dateStart(String dateStart) {
    return Text(dateStartTimer,
        style: TextStyle(
            color: timerActive == true ? Colors.amber : Colors.grey[600],
            fontWeight: FontWeight.w700,
            fontSize: 12));
  }

  Widget pcName(String name) {
    return Text(name,
        style: TextStyle(
            color: timerActive == true ? Colors.amber : Colors.grey[600],
            fontWeight: FontWeight.w700,
            fontSize: 12));
  }

  Widget showTimer() {
    return Text(timerPretty(counter),
        style: TextStyle(
            color: timerActive == true ? Colors.amber : Colors.grey[600],
            fontWeight: FontWeight.w700,
            fontSize: 60));
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
      inactiveThumbColor: Colors.grey[700],
      onChanged: (bool value) {
        setState(() {
          if (counter <= 0) {
            timeEnd = false;
          }
          timerActive = value;
        });
        startTimer();
      },
    );
  }

  void stopMusic() {
    setState(() {
      timeEnd = false;
    });
    service.invoke("stopMusic");
  }
}
