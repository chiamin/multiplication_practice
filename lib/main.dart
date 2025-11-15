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
      title: 'Icon 測試',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Icon測試'),
        ),
        body: Center(
          child: Container(
            width: 240,
            height: 240,
            color: Colors.yellowAccent, // 背景放超明顯
            alignment: Alignment.center,
            child: Image.asset(
              'assets/icons/add.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              // 如果載圖失敗，會顯示一個紅色大錯誤 Icon
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

