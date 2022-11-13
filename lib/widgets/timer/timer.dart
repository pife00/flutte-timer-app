import 'dart:convert';
import 'dart:developer';
import '../../models/CountData.dart';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

final player = AudioPlayer();

class TimerLess extends StatefulWidget {
  TimerLess(
      {super.key,
      required this.tick,
      this.timerName = 1,
      required this.sendData});

  final FlutterBackgroundService tick;
  int timerName = 1;
  final Function(int, String) sendData;

  @override
  State<TimerLess> createState() => _TimerState();
}

class _TimerState extends State<TimerLess> {
  bool _canVibrate = true;
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

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  String timerData = '';
  late String name;

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

  Future playAudio() async {
    await player.play(AssetSource('sounds/Ereve.mp3'));
  }

  Future stopAudio() async {
    await player.stop();
  }

  getDataTimer() async {
    var prefs = await _prefs;
    final String? data = await prefs.getString('timersData');
    List<dynamic> json = jsonDecode(data!);
    var myTimer = json.map((el) {
      var timer = CountData.fromJson(el);
      if (timer.name == name) {
        return el;
      }
    });

    print(myTimer);

    //print(timers[0].name);
    //var json = jsonDecode(data!);
    // List result = json as List<dynamic>;
    // var a = CountData.fromJson(result as Map<String, dynamic>);

    setState(() {
      timerData = 'data!';
    });
  }

  @override
  void initState() {
    super.initState();
    getDataTimer();
    name = 'PC:${widget.timerName}';
    widget.tick.on('update').listen((event) async {
      if (counter > 0) {
        if (timerActive == true) {
          setState(() => counter--);
          widget.sendData(counter, name);
          if (counter <= 0) {
            setState(() {
              timerActive = false;
              playAudio();

              _dialogBuilder(context);
              isEndTimer = true;
            });

            await onVibration();
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
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(timerPretty(counter),
                          style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.w500,
                              fontSize: 60)),
                    ),
                    playButton(),
                    Text(
                      '$timerData',
                      style: TextStyle(color: Colors.amber),
                    )
                  ],
                ),
              ),
            )),
      ],
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

  Widget playButton() {
    return !timerActive
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
            ));
  }
}
