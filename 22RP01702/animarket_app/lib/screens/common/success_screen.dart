import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class SuccessScreen extends StatelessWidget {
  final String message;
  final Widget? nextScreen;

  const SuccessScreen({Key? key, required this.message, this.nextScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: kPrimaryGreen,
                child: Icon(Icons.check, color: Colors.white, size: 48),
              ),
              SizedBox(height: 24),
              Text('Success!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: kPrimaryGreen)),
              SizedBox(height: 16),
              Text(message, style: TextStyle(fontSize: 18, color: kDarkText), textAlign: TextAlign.center),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (nextScreen != null) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => nextScreen!),
                      (route) => false,
                    );
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                ),
                child: Text('Continue', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
