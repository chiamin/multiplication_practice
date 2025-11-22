part of 'multiplication_practice_page.dart';

/// 出題、判斷正確與否、結束一組等邏輯
mixin MultiplicationPracticeLogic on _MultiplicationPracticeBase {
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

  String get _operationSymbol {
    switch (_operation) {
      case Operation.add:
        return '+';
      case Operation.subtract:
        return '−';
      case Operation.multiply:
        return '×';
      case Operation.divide:
        return '÷';
    }
  }

  void _generateNewQuestion() {
    setState(() {
      switch (_operation) {
        case Operation.add:
          _a = _randomNumberWithDigits(_digitsA);
          _b = _randomNumberWithDigits(_digitsB);
          break;
        case Operation.subtract:
          int x = _randomNumberWithDigits(_digitsA);
          int y = _randomNumberWithDigits(_digitsB);
          // 不要出現負數，讓大的數放前面
          if (x >= y) {
            _a = x;
            _b = y;
          } else {
            _a = y;
            _b = x;
          }
          break;
        case Operation.multiply:
          _a = _randomNumberWithDigits(_digitsA);
          _b = _randomNumberWithDigits(_digitsB);
          break;
        case Operation.divide:
          _generateDivisionQuestion();
          break;
      }

      _message = '';
      _answerController.clear();
    });
  }

  void _generateDivisionQuestion() {
    final int minA = pow(10, _digitsA - 1).toInt();
    final int maxA = pow(10, _digitsA).toInt() - 1;
    final int minB = pow(10, _digitsB - 1).toInt();
    final int maxB = pow(10, _digitsB).toInt() - 1;

    const int maxTries = 100;

    for (int i = 0; i < maxTries; i++) {
      final int b = minB + _random.nextInt(maxB - minB + 1);
      final int q = 2 + _random.nextInt(8); // 商控制在 2~9，比較好算
      final int a = b * q;
      if (a >= minA && a <= maxA) {
        _a = a;
        _b = b;
        return;
      }
    }

    // 如果上面實在找不到符合位數的，就退一步，用簡單一點的整除
    final int fallbackB = 2 + _random.nextInt(8);
    final int fallbackQ = 2 + _random.nextInt(8);
    _a = fallbackB * fallbackQ;
    _b = fallbackB;
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

    // 正確答案
    late final int correct;
    switch (_operation) {
      case Operation.add:
        correct = _a + _b;
        break;
      case Operation.subtract:
        correct = _a - _b;
        break;
      case Operation.multiply:
        correct = _a * _b;
        break;
      case Operation.divide:
        correct = _a ~/ _b;
        break;
    }

    if (value == correct) {
      // 答對
      setState(() {
        _message = '答對了！太棒了 🎉';
        _messageColor = Colors.green;
      });

      // 播放答對音效
      try {
        await _player.play(
          AssetSource('sounds/ding.mp3'),
        );
      } catch (e) {
        debugPrint('播放音效錯誤: $e');
      }

      // 答對稍微停一下再進下一題或結束
      await Future.delayed(const Duration(milliseconds: 1000));
      await _onQuestionFinished();
    } else {
      final wrong = _answerController.text; // 記住錯誤答案（原樣）

      setState(() {
        _message = '不是 $wrong 喔，再試試 🙈';
        _messageColor = Colors.red;
        _answerController.clear(); // 清掉輸入框，讓下一次輸入直接重打
      });

      // 播放答錯音效
      try {
        await _player.play(
          AssetSource('sounds/eoh.mp3'),
        );
      } catch (e) {
        debugPrint('播放音效錯誤: $e');
      }

      _requestFocus();
    }
  }

  void _requestFocus() {
    FocusScope.of(context).requestFocus(_answerFocus);
  }

  // 當一題結束（答對）時呼叫
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

  // 清除輸入框
  void _clearAnswerField() {
    setState(() {
      _answerController.clear();
      _message = '';
    });
    _requestFocus();
  }

  Future<void> _showSessionCompletedDialog() async {
    if (!mounted) return;

    // 在這裡重新計算 isTablet
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.shortestSide >= 600;

    // ① 先顯示 4 秒的慶祝動畫（兔子 + cheer 音效）
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) {
        return Center(
          child: SizedBox(
            width: isTablet ? 400 : 300,
            height: isTablet ? 300 : 220,
            child: RabbitsCelebration(
              isTablet: isTablet,
            ),
          ),
        );
      },
    );

    try {
      await _player.play(
        AssetSource('sounds/cheer.mp3'),
      );
    } catch (e) {
      debugPrint('播放慶祝音效錯誤: $e');
    }

    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    // ③ 關掉剛剛那個慶祝動畫的 dialog
    Navigator.of(context, rootNavigator: true).pop();

    // ④ 再顯示「本次練習完成」的選項對話框
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          '本次練習完成',
          style: TextStyle(
            fontSize: isTablet ? 32 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '你已完成 $_questionsPerSet 題練習，要再做一組嗎？',
          style: TextStyle(
            fontSize: isTablet ? 26 : 20,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // 回到設定
            },
            child: Text(
              '回到設定',
              style: TextStyle(fontSize: isTablet ? 22 : 18),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true); // 再做一組
            },
            child: Text(
              '再做一組',
              style: TextStyle(
                fontSize: isTablet ? 26 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;

    // ⑤ 根據使用者選擇決定後續行為
    if (result == true) {
      // 再做一組：重置計數、重新出題
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
}

