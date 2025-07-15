import 'package:flutter/material.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({Key? key}) : super(key: key);

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  int _seconds = 0;
  bool _isRunning = false;
  late final Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _stopwatch.start();
    _tick();
  }

  void _tick() async {
    while (_isRunning) {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRunning) break;
      setState(() => _seconds = _stopwatch.elapsed.inSeconds);
    }
  }

  void _stopTimer() {
    setState(() => _isRunning = false);
    _stopwatch.stop();
  }

  void _resetTimer() {
    _stopwatch.reset();
    setState(() => _seconds = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Study Timer'),
        backgroundColor: Colors.blue[800],
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                child: Column(
                  children: [
                    Text(
                      '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isRunning ? Colors.orange : Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(100, 48),
                          ),
                          onPressed: _isRunning ? _stopTimer : _startTimer,
                          child: Text(_isRunning ? 'Stop' : 'Start', style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[400],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(100, 48),
                          ),
                          onPressed: _resetTimer,
                          child: const Text('Reset', style: TextStyle(fontSize: 18)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Stay focused and productive!\nUse the timer for your study sessions.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}
