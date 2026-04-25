import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class FocusTimerScreen extends StatefulWidget {
  final int durationInMinutes;
  const FocusTimerScreen({super.key, required this.durationInMinutes});

  @override
  State<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends State<FocusTimerScreen> {
  late int _secondsRemaining;
  Timer? _timer;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.durationInMinutes * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _onTimerFinished();
      }
    });
  }

  void _onTimerFinished() {
    NotificationService().showInstantNotification(
      "Focus Session Ended! 🔥",
      "You nailed it! Take a short break now."
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Time's Up! 🏆"),
        content: const Text("Great focus session. Ready for more later?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Finish")),
        ],
      ),
    ).then((_) => Navigator.pop(context));
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),   
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Focus Mode", style: TextStyle(color: Colors.white70, fontSize: 24)),
            const SizedBox(height: 20),
            Text(
              _formatTime(_secondsRemaining),
              style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white, size: 40),
                  onPressed: () {
                    setState(() {
                      if (_isPaused) {
                        _startTimer();
                      } else {
                        _timer?.cancel();
                      }
                      _isPaused = !_isPaused;
                    });
                  },
                ),
                const SizedBox(width: 30),
                IconButton(
                  icon: const Icon(Icons.stop, color: Colors.redAccent, size: 40),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
