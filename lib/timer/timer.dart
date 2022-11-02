import 'package:flutter/material.dart';

class Timer extends StatefulWidget {
  const Timer({super.key});
  //Function tick

  @override
  State<Timer> createState() => _TimerState();
}

class _TimerState extends State<Timer> {
  int counter = 0;
  bool timerActive = false;

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
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}
