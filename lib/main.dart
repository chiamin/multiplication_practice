import 'package:flutter/material.dart';

void main() {
  runApp(const TestIconApp());
}

class TestIconApp extends StatelessWidget {
  const TestIconApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Icon 測試')),
        body: Center(
          child: Image.asset(
            'assets/icons/add.png',
            width: 200,
            height: 200,
          ),
        ),
      ),
    );
  }
}

