import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:audioplayers/audioplayers.dart';

final player = AudioPlayer();

class TimerLess extends StatefulWidget {
  const TimerLess({super.key, required this.tick});
  final FlutterBackgroundService tick;

  @override
  State<TimerLess> createState() => _TimerState();
}

class _TimerState extends State<TimerLess> {
  int counter = 0;
  bool timerActive = false;
  int valueToPick = 15;
  int valueToReach = 0;

  playAudio() async {
    await player.play(DeviceFileSource('assets/sounds/yosuga'));
    //await player.play(source)
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
  void initState() async {
    super.initState();
    await playAudio();
    widget.tick.on('update').listen((event) {
      if (counter > 0) {
        if (timerActive == true) {
          setState(() => counter--);
          if (counter <= 0) {
            timerActive = false;
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
                                child: Text(
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
          child: Center(
              child: Text(timerPretty(counter),
                  style: const TextStyle(color: Colors.amber, fontSize: 50))),
        ),
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
    );
  }
}
