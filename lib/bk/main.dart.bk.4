import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '乘法練習',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const MultiplicationPracticePage(),
    );
  }
}

class MultiplicationPracticePage extends StatefulWidget {
  const MultiplicationPracticePage({super.key});

  @override
  State<MultiplicationPracticePage> createState() =>
      _MultiplicationPracticePageState();
}

class _MultiplicationPracticePageState
    extends State<MultiplicationPracticePage> {
  final Random _random = Random();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocus = FocusNode();

  late int _a;
  late int _b;
  String _message = '';
  Color _messageColor = Colors.black;

  // 音效播放器
  final AudioPlayer _player = AudioPlayer();

  // 設定：位數（預設 1 位數 × 1 位數）
  int _digitsA = 1; // 第一個數字的位數：1~9
  int _digitsB = 1; // 第二個數字的位數：1~9

  // 一次要練習幾題
  int _questionsPerSet = 10; // 可在設定頁修改
  int _answeredCount = 0; // 本組已完成題數

  // 是否在設定頁
  bool _inSettings = true;

  // 手寫板的點
  final List<Offset?> _points = [];

  @override
  void initState() {
    super.initState();
    // 一開始先顯示設定頁
  }

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocus.dispose();
    _player.dispose();
    super.dispose();
  }

  /// 依照位數產生亂數
  int _randomNumberWithDigits(int digits) {
    // 1 位數沿用你原本的 2~9
    if (digits <= 1) {
      return 2 + _random.nextInt(8); // 2~9
    }

    // 2 位數：10~99，3 位數：100~999 ... 直到 9 位數
    final int min = pow(10, digits - 1).toInt();
    final int max = pow(10, digits).toInt() - 1;
    return min + _random.nextInt(max - min + 1);
  }

  void _generateNewQuestion() {
    setState(() {
      _a = _randomNumberWithDigits(_digitsA);
      _b = _randomNumberWithDigits(_digitsB);
      _answerController.clear();
      _message = '';
      _points.clear(); // 換題時把手寫板也清掉
    });
  }

  Future<void> _checkAnswer() async {
    final text = _answerController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _message = '請先輸入答案';
        _messageColor = Colors.orange;
      });
      return;
    }

    final int? value = int.tryParse(text);
    if (value == null) {
      setState(() {
        _message = '請輸入整數喔';
        _messageColor = Colors.orange;
      });
      return;
    }

    final correct = _a * _b;
    if (value == correct) {
      setState(() {
        _message = '答對了！太棒了 🎉';
        _messageColor = Colors.green;
      });

      // 播放答對音效 (ding.mp3)
      try {
        await _player.play(
          AssetSource('sounds/ding.mp3'),
        );
      } catch (e) {
        debugPrint('播放音效錯誤: $e');
      }

      // 答對稍微停一下再進下一題或結束
      await Future.delayed(const Duration(milliseconds: 600));
      await _onQuestionFinished();
    } else {
      setState(() {
        // 依你的要求：不要顯示正確答案
        _message = '答錯了，再試試 🙈';
        _messageColor = Colors.red;
      });

      // 選取整個輸入，方便重新輸入
      _answerController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _answerController.text.length,
      );
      _requestFocus();
    }
  }

  void _requestFocus() {
    FocusScope.of(context).requestFocus(_answerFocus);
  }

  // 當一題結束（答對或按「換一題」）時呼叫
  Future<void> _onQuestionFinished() async {
    setState(() {
      _answeredCount++;
    });

    if (_answeredCount >= _questionsPerSet) {
      // 本組題目完成
      await _showSessionCompletedDialog();
    } else {
      _generateNewQuestion();
      _requestFocus();
    }
  }

  // 清除手寫板
  void _clearHandwriting() {
    setState(() {
      _points.clear();
    });
  }

  Future<void> _showSessionCompletedDialog() async {
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('本次練習完成'),
        content: Text('你已完成 $_questionsPerSet 題練習，要再做一組嗎？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // 回到設定
            },
            child: const Text('回到設定'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true); // 再做一組
            },
            child: const Text('再做一組'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == true) {
      // 再做一組：保留目前設定，只重置進度與題目
      setState(() {
        _answeredCount = 0;
        _message = '';
      });
      _generateNewQuestion();
      _requestFocus();
    } else {
      // 回到設定頁
      setState(() {
        _inSettings = true;
        _message = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.shortestSide >= 600;

    return Scaffold(
      appBar: AppBar(
        leading: !_inSettings
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _inSettings = true;
                  });
                },
              )
            : null,
        title: Text(_inSettings ? '設定位數' : '乘法練習'),
        centerTitle: true,
        actions: [
          if (!_inSettings)
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: '設定位數',
              onPressed: () {
                setState(() {
                  _inSettings = true;
                });
              },
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _inSettings
                ? _buildSettingsView(isTablet)
                : _buildPracticeView(isTablet),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsView(bool isTablet) {
    final double labelFontSize = isTablet ? 24 : 18;
    final double dropdownFontSize = isTablet ? 22 : 16;
    final double buttonFontSize = isTablet ? 24 : 18;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '請選擇練習設定',
          style: TextStyle(
            fontSize: isTablet ? 28 : 20,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // 第一個數字的位數
        Text(
          '第一個數字的位數',
          style: TextStyle(fontSize: labelFontSize),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _digitsA,
          items: List.generate(
            9,
            (i) => DropdownMenuItem(
              value: i + 1,
              child: Text('${i + 1} 位數'),
            ),
          ),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _digitsA = value;
            });
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          style: TextStyle(fontSize: dropdownFontSize),
        ),

        const SizedBox(height: 24),

        // 第二個數字的位數
        Text(
          '第二個數字的位數',
          style: TextStyle(fontSize: labelFontSize),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _digitsB,
          items: List.generate(
            9,
            (i) => DropdownMenuItem(
              value: i + 1,
              child: Text('${i + 1} 位數'),
            ),
          ),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _digitsB = value;
            });
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          style: TextStyle(fontSize: dropdownFontSize),
        ),

        const SizedBox(height: 24),

        // 一次要練習幾題
        Text(
          '一次要練習幾題',
          style: TextStyle(fontSize: labelFontSize),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _questionsPerSet,
          items: const [
            DropdownMenuItem(value: 5, child: Text('5 題')),
            DropdownMenuItem(value: 10, child: Text('10 題')),
            DropdownMenuItem(value: 15, child: Text('15 題')),
            DropdownMenuItem(value: 20, child: Text('20 題')),
            DropdownMenuItem(value: 30, child: Text('30 題')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _questionsPerSet = value;
            });
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          style: TextStyle(fontSize: dropdownFontSize),
        ),

        const SizedBox(height: 32),

        FilledButton(
          onPressed: () {
            _answeredCount = 0;
            _generateNewQuestion();
            setState(() {
              _inSettings = false;
            });
            _requestFocus();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              '開始練習',
              style: TextStyle(
                fontSize: buttonFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeView(bool isTablet) {
    final double questionFontSize = isTablet ? 60 : 36;
    final double inputFontSize = isTablet ? 32 : 24;
    final double buttonFontSize = isTablet ? 26 : 18;

    // 目前是第幾題（畫面顯示用：1-based，但不要超過總題數）
    final currentIndexForDisplay = (_answeredCount < _questionsPerSet)
        ? _answeredCount + 1
        : _questionsPerSet;

    final progressValue = _questionsPerSet > 0
        ? _answeredCount / _questionsPerSet
        : 0.0;

    return Column(
      children: [
        // 上方：進度 + 題目 + 輸入 + 按鈕 + 訊息
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 進度列
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progressValue.clamp(0.0, 1.0),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '第 $currentIndexForDisplay / $_questionsPerSet 題',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 顯示目前設定（例如：1 位數 × 3 位數）
            Text(
              '目前設定：${_digitsA} 位數 × ${_digitsB} 位數',
              style: TextStyle(
                fontSize: isTablet ? 22 : 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),

            Text(
              '$_a × $_b = ?',
              style: TextStyle(
                fontSize: questionFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _answerController,
              focusNode: _answerFocus,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: inputFontSize),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '請輸入答案',
              ),
              onSubmitted: (_) => _checkAnswer(),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilledButton(
                  onPressed: _checkAnswer,
                  child: Text(
                    '檢查答案',
                    style: TextStyle(fontSize: buttonFontSize),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    // 不管有沒有作答，直接算一題結束，換下一題或結束本組
                    _onQuestionFinished();
                  },
                  child: Text(
                    '換一題',
                    style: TextStyle(fontSize: buttonFontSize),
                  ),
                ),
                OutlinedButton(
                  onPressed: _clearHandwriting,
                  child: Text(
                    '清除筆跡',
                    style: TextStyle(fontSize: buttonFontSize),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (_message.isNotEmpty)
              Text(
                _message,
                style: TextStyle(
                  fontSize: isTablet ? 24 : 18,
                  color: _messageColor,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),

        const SizedBox(height: 12),

        // 下方：手寫板區域（佔滿剩餘空間）
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _points.add(details.localPosition);
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _points.add(details.localPosition);
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    _points.add(null); // 分隔不同筆畫
                  });
                },
                child: CustomPaint(
                  painter: HandwritingPainter(_points),
                  child: Container(), // 撐滿空間
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 手寫板的畫筆
class HandwritingPainter extends CustomPainter {
  final List<Offset?> points;

  HandwritingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HandwritingPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

