import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';

class TimerLess extends StatefulWidget {
  const TimerLess({super.key, required this.tick});
  final FlutterBackgroundService tick;

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

  int counter = 5;
  bool timerActive = false;
  int valueToPick = 15;
  int valueToReach = 0;

  String timerPretty(int count) {
    var minutes = (count / 60).floor();
    var seconds = (count % 60);
    if (seconds < 10) {
      return '$minutes : 0$seconds';
    }
    return '$minutes : $seconds';
  }

  @override
  void initState() {
    super.initState();

    widget.tick.on('update').listen((event) async {
      if (counter > 0) {
        if (timerActive == true) {
          setState(() => counter--);
          if (counter <= 0) {
            timerActive = false;
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
                                  ))
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
                    playButton()
                  ],
                ),
              ),
            )),
      ],
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
