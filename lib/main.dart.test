import 'package:flutter/material.dart';

void main() {
  runApp(const TestIconApp());
}

class TestIconApp extends StatelessWidget {
  const TestIconApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Icon 測試 - network',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Icon測試 - network'),
        ),
        body: Center(
          child: Container(
            width: 240,
            height: 240,
            color: Colors.yellowAccent,
            alignment: Alignment.center,
            child: Image.network(
              // 注意：這裡直接用「網頁上實際能打開的路徑」
              'assets/assets/icons/add.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.error,
                  size: 200,
                  color: Colors.red,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

