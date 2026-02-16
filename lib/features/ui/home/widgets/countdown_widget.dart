import 'dart:async';
import 'package:flutter/material.dart';

class SeatCountdownTimer extends StatefulWidget {
  final DateTime expiryTime;
  final VoidCallback onTimerEnd;

  const SeatCountdownTimer({
    super.key,
    required this.expiryTime,
    required this.onTimerEnd,
  });

  @override
  State<SeatCountdownTimer> createState() => _SeatCountdownTimerState();
}

class _SeatCountdownTimerState extends State<SeatCountdownTimer> {
  late Timer _timer;
  late Duration _remainingTime;

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    _startTimer();
  }

  void _calculateRemainingTime() {
    _remainingTime = widget.expiryTime.difference(DateTime.now());
    if (_remainingTime.isNegative) {
      _remainingTime = Duration.zero;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _calculateRemainingTime();
        if (_remainingTime.inSeconds <= 0) {
          _timer.cancel();
          widget.onTimerEnd();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _remainingTime.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = _remainingTime.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');

    return Text(
      '$minutes:$seconds',
      style: const TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.normal,
        fontSize: 18,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}
