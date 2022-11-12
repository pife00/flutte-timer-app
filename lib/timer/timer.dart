import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:audioplayers/audioplayers.dart';

final player = AudioPlayer();

class TimerLess extends StatefulWidget {
  TimerLess(
      {super.key,
      required this.tick,
      this.timerName = 1,
      required this.sendData});

  final FlutterBackgroundService tick;
  int timerName = 1;
  final Function(int) sendData;

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

  String timerPretty(int count) {
    var minutes = (count / 60).floor();
    var seconds = (count % 60);
    if (seconds < 10) {
      return '$minutes : 0$seconds';
    }
    return '$minutes : $seconds';
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
    // widget.sendData(counter);

    widget.tick.on('update').listen((event) async {
      if (counter > 0) {
        if (timerActive == true) {
          setState(() => counter--);
          widget.sendData(counter);

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

  void sendData(int counter) {
    log('$Counter');
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
