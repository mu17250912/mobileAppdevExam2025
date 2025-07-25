import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Medication Calendar'), backgroundColor: Colors.blueAccent),
      backgroundColor: Color(0xFFE6EDFF),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Calendar grid (mocked)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) => Text(['S','M','T','W','T','F','S'][i], style: TextStyle(fontWeight: FontWeight.bold))),
                  ),
                  SizedBox(height: 8),
                  // Mocked days
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(30, (i) => Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: (i == 12) ? Colors.blueAccent : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${i+1}', style: TextStyle(color: (i == 12) ? Colors.white : Colors.black)),
                    )),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text('94%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    Text('ADHERENCE RATE', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
                Column(
                  children: [
                    Text('28', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    Text('DOSES TAKEN', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 