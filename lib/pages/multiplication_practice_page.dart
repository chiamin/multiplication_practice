import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/operation.dart';
import '../widgets/handwriting_painter.dart';
import '../widgets/rabbits_celebration.dart';
import '../utils/image_loader.dart';

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
  
  // 除法專用：餘數輸入框
  final TextEditingController _remainderController = TextEditingController();
  final FocusNode _remainderFocus = FocusNode();
  
  // 當前正在編輯的答案框（用於除法）：'quotient' 或 'remainder'
  String _currentAnswerField = 'quotient';

  late int _a;
  late int _b;
  String _message = '';
  Color _messageColor = Colors.black;

  // 音效播放器
  final AudioPlayer _player = AudioPlayer();

  // 設定：位數
  int _digitsA = 1; // 第一個數字的位數：1~9
  int _digitsB = 1; // 第二個數字的位數：1~9

  // 一次要練習幾題
  int _questionsPerSet = 5;
  int _answeredCount = 0; // 本組已完成題數

  // 選擇的運算種類（預設乘法）
  Operation _operation = Operation.add;

  // 是否在設定頁
  bool _inSettings = true;

  // 手寫板的點
  final List<Offset?> _points = [];

  // 上一次 onPanUpdate 的時間（毫秒），用來節流，避免太多 setState
  int _lastPanUpdateMs = 0;

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocus.dispose();
    _remainderController.dispose();
    _remainderFocus.dispose();
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

      _answerController.clear();
      _remainderController.clear();
      _message = '';
      _currentAnswerField = 'quotient'; // 重置為商
      _points.clear(); // 換題時把手寫板也清掉
    });
  }

  /// 產生除法題目（可以有餘數）
  void _generateDivisionQuestion() {
    // 位數對應的範圍
    int minA =
        _digitsA <= 1 ? 2 : pow(10, _digitsA - 1).toInt(); // 1 位數沿用 2~9
    int maxA = _digitsA <= 1 ? 9 : pow(10, _digitsA).toInt() - 1;
    int minB = _digitsB <= 1 ? 2 : pow(10, _digitsB - 1).toInt();
    int maxB = _digitsB <= 1 ? 9 : pow(10, _digitsB).toInt() - 1;

    const int maxTries = 1000;
    for (int i = 0; i < maxTries; i++) {
      final int b = minB + _random.nextInt(maxB - minB + 1);
      final int q = 1 + _random.nextInt(9); // 商控制在 1~9
      final int r = _random.nextInt(b); // 餘數：0 到 b-1
      final int a = b * q + r;
      if (a >= minA && a <= maxA) {
        _a = a;
        _b = b;
        return;
      }
    }

    // 如果上面實在找不到符合位數的，就退一步，用簡單一點的
    final int fallbackB = 2 + _random.nextInt(8);
    final int fallbackQ = 1 + _random.nextInt(8);
    final int fallbackR = _random.nextInt(fallbackB);
    _a = fallbackB * fallbackQ + fallbackR;
    _b = fallbackB;
  }

  Future<void> _checkAnswer() async {
    // 除法需要檢查商和餘數
    if (_operation == Operation.divide) {
      final quotientText = _answerController.text.trim();
      final remainderText = _remainderController.text.trim();
      
      if (quotientText.isEmpty || remainderText.isEmpty) {
        setState(() {
          _message = '請輸入商和餘數';
          _messageColor = Colors.orange;
        });
        return;
      }

      final int? quotient = int.tryParse(quotientText);
      final int? remainder = int.tryParse(remainderText);
      
      if (quotient == null || remainder == null) {
        setState(() {
          _message = '請輸入整數喔';
          _messageColor = Colors.orange;
        });
        return;
      }

      // 檢查餘數是否小於除數
      if (remainder >= _b) {
        setState(() {
          _message = '餘數應該小於除數喔';
          _messageColor = Colors.orange;
        });
        return;
      }

      final int correctQuotient = _a ~/ _b;
      final int correctRemainder = _a % _b;

      if (quotient == correctQuotient && remainder == correctRemainder) {
        setState(() {
          _message = '答對了！太棒了 🎉';
          _messageColor = Colors.green;
        });

        // 播放答對音效
        try {
          // 先停止之前的音效（如果有）
          await _player.stop();
          await _player.play(
            AssetSource('sounds/ding.mp3'),
          );
        } catch (e) {
          debugPrint('播放答對音效錯誤: $e');
        }

        // 答對稍微停一下再進下一題或結束
        await Future.delayed(const Duration(milliseconds: 1000));
        await _onQuestionFinished();
      } else {
        setState(() {
          _message = '不對喔，再試試 🙈';
          _messageColor = Colors.red;
          _answerController.clear();
          _remainderController.clear();
          _currentAnswerField = 'quotient';
        });

        // 播放答錯音效
        try {
          // 先停止之前的音效（如果有）
          await _player.stop();
          await _player.play(
            AssetSource('sounds/eoh.mp3'),
          );
        } catch (e) {
          debugPrint('播放答錯音效錯誤: $e');
        }

        _requestFocus();
      }
      return;
    }

    // 其他運算（加、減、乘）
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

    // 根據運算種類計算正確答案
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
        // 不會執行到這裡，因為上面已經處理了
        correct = 0;
        break;
    }

    if (value == correct) {
      setState(() {
        _message = '答對了！太棒了 🎉';
        _messageColor = Colors.green;
      });

      // 播放答對音效
      try {
        // 先停止之前的音效（如果有）
        await _player.stop();
        await _player.play(
          AssetSource('sounds/ding.mp3'),
        );
      } catch (e) {
        debugPrint('播放答對音效錯誤: $e');
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
        // 先停止之前的音效（如果有）
        await _player.stop();
        await _player.play(
          AssetSource('sounds/eoh.mp3'),
        );
      } catch (e) {
        debugPrint('播放答錯音效錯誤: $e');
      }

      _requestFocus();
    }
  }

  void _requestFocus() {
    if (_operation == Operation.divide && _currentAnswerField == 'remainder') {
      FocusScope.of(context).requestFocus(_remainderFocus);
    } else {
      FocusScope.of(context).requestFocus(_answerFocus);
    }
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

  // 清除答案欄
  void _clearAnswerField() {
    setState(() {
      _answerController.clear();
      _remainderController.clear();
      _currentAnswerField = 'quotient';
    });
    _requestFocus();
  }
  
  // 切換到餘數輸入框（用於除法）
  void _switchToRemainderField() {
    setState(() {
      _currentAnswerField = 'remainder';
    });
    FocusScope.of(context).requestFocus(_remainderFocus);
  }

  Future<void> _showSessionCompletedDialog() async {
    if (!mounted) return;

    // 在這裡重新計算 isTablet
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.shortestSide >= 600;

    // 1. 先顯示慶祝動畫（兔子 + cheer 音效）
    // 使用一個變數來追蹤 dialog 是否已經關閉
    bool celebrationDialogClosed = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,       // 背景保持透明
      useRootNavigator: true,
      builder: (_) => RabbitsCelebration(isTablet: isTablet),
    ).then((_) {
      celebrationDialogClosed = true;
    });

    // 2. 等待動畫播完（4秒）
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    // 3. 安全地關掉慶祝動畫的 dialog
    try {
      // 檢查 dialog 是否還在顯示
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      // 確保 dialog 完全關閉
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('關閉慶祝動畫 dialog 錯誤: $e');
    }

    if (!mounted) return;

    // 4. 再顯示「本次練習完成」的選項對話框
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) {
        // 重新獲取 isTablet（因為 context 可能改變）
        final dialogSize = MediaQuery.of(context).size;
        final bool dialogIsTablet = dialogSize.shortestSide >= 600;
        
        return AlertDialog(
          title: Text(
            '本次練習完成',
            style: TextStyle(
              fontSize: dialogIsTablet ? 32 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '你已完成 $_questionsPerSet 題練習，要再做一組嗎？',
            style: TextStyle(
              fontSize: dialogIsTablet ? 26 : 20,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // 回到設定
              },
              child: Text(
                '回到設定',
                style: TextStyle(
                  fontSize: dialogIsTablet ? 24 : 18,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true); // 再做一組
              },
              child: Text(
                '再做一組',
                style: TextStyle(
                  fontSize: dialogIsTablet ? 26 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
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


  // === 鍵盤大小相關：這三個一起控制 ===

  double _keySize(bool isTablet) => isTablet ? 80 : 70; // 按鍵邊長（變大了）
  double _digitFontSize(bool isTablet) =>
      _keySize(isTablet) * 0.5; // 數字大小
  double _actionIconSize(bool isTablet) =>
      _keySize(isTablet) * 0.7; // 送出/清除圖示大小

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
        //title: Text(_inSettings ? '設定練習' : '算術練習'),
        centerTitle: true,
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

  // 圖片版：四則運算（加、減、乘、除）
  Widget _buildOperationCardImage(
    Operation op,
    String iconName,
    String label,
    bool isTablet,
  ) {
    final bool selected = _operation == op;
    final double iconSize = isTablet ? 40 : 28;
    final double fontSize = isTablet ? 20 : 14;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _operation = op;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.blue.withOpacity(0.1) : Colors.white,
            border: Border.all(
              color: selected ? Colors.blue : Colors.grey.shade400,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ImageLoader.loadIcon(
                iconName: iconName,
                width: iconSize,
                height: iconSize,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? Colors.blue : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 共用：數字小卡片（位數、題數）
  Widget _buildNumberCard({
    required int value,
    required int selectedValue,
    required bool isTablet,
    required VoidCallback onTap,
  }) {
    final bool selected = value == selectedValue;
    final double fontSize = isTablet ? 22 : 16;
    final double size = isTablet ? 70 : 55;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.green.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: selected ? Colors.green : Colors.grey.shade400,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.green.shade800 : Colors.grey.shade900,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsView(bool isTablet) {
    final double labelFontSize = isTablet ? 24 : 18;
    final double buttonFontSize = isTablet ? 24 : 18;

    return SingleChildScrollView(
      child: Column(
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
          const SizedBox(height: 24),

          // 🔹 四則運算選擇（全部用你的 icon）
          Text(
            '要練習的運算',
            style: TextStyle(fontSize: labelFontSize),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildOperationCardImage(
                Operation.add,
                'add.png',
                '加法',
                isTablet,
              ),
              _buildOperationCardImage(
                Operation.subtract,
                'subtract.png',
                '減法',
                isTablet,
              ),
              _buildOperationCardImage(
                Operation.multiply,
                'multiply.png',
                '乘法',
                isTablet,
              ),
              _buildOperationCardImage(
                Operation.divide,
                'divide.png',
                '除法',
                isTablet,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 🔹 第一個數字的位數（用數字卡片 1~9）
          Text(
            '第一個數字的位數',
            style: TextStyle(fontSize: labelFontSize),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(9, (i) {
              final v = i + 1;
              return _buildNumberCard(
                value: v,
                selectedValue: _digitsA,
                isTablet: isTablet,
                onTap: () {
                  setState(() {
                    _digitsA = v;
                  });
                },
              );
            }),
          ),

          const SizedBox(height: 24),

          // 🔹 第二個數字的位數
          Text(
            '第二個數字的位數',
            style: TextStyle(fontSize: labelFontSize),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(9, (i) {
              final v = i + 1;
              return _buildNumberCard(
                value: v,
                selectedValue: _digitsB,
                isTablet: isTablet,
                onTap: () {
                  setState(() {
                    _digitsB = v;
                  });
                },
              );
            }),
          ),

          const SizedBox(height: 24),

          // 🔹 一次要練習幾題（數字卡片 5,10,15,20,30）
          Text(
            '一次要練習幾題',
            style: TextStyle(fontSize: labelFontSize),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [5, 10, 15, 20, 30].map((v) {
              return _buildNumberCard(
                value: v,
                selectedValue: _questionsPerSet,
                isTablet: isTablet,
                onTap: () {
                  setState(() {
                    _questionsPerSet = v;
                  });
                },
              );
            }).toList(),
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
      ),
    );
  }

  // 數字鍵盤按鍵
  Widget _buildDigitKey(int digit, bool isTablet) {
    final double size = _keySize(isTablet);
    final double fontSize = _digitFontSize(isTablet);

    return InkWell(
      onTap: () {
        setState(() {
          // 除法時，根據當前焦點決定輸入到哪個框
          if (_operation == Operation.divide) {
            if (_currentAnswerField == 'remainder') {
              _remainderController.text =
                  _remainderController.text + digit.toString();
              _remainderController.selection = TextSelection.collapsed(
                offset: _remainderController.text.length,
              );
            } else {
              _answerController.text =
                  _answerController.text + digit.toString();
              _answerController.selection = TextSelection.collapsed(
                offset: _answerController.text.length,
              );
            }
          } else {
            _answerController.text =
                _answerController.text + digit.toString();
            _answerController.selection = TextSelection.collapsed(
              offset: _answerController.text.length,
            );
          }
        });
        if (_operation == Operation.divide && _currentAnswerField == 'remainder') {
          FocusScope.of(context).requestFocus(_remainderFocus);
        } else {
          _requestFocus();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: Text(
          '$digit',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // 行為按鍵（送出 / 清除答案）跟數字一樣大小
  Widget _buildActionKey({
    required bool isTablet,
    required Widget icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final double size = _keySize(isTablet);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade300),
          ),
          child: icon,
        ),
      ),
    );
  }

  // 建立題目和答案框（內嵌在一起）
  Widget _buildQuestionWithAnswer(
    bool isTablet,
    double questionFontSize,
    double inputFontSize,
  ) {
    // 答案框的寬度
    final double answerBoxWidth = isTablet ? 120 : 80;
    final double answerBoxHeight = isTablet ? 60 : 45;

    // 除法：顯示兩個答案框（商和餘數）
    if (_operation == Operation.divide) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$_a $_operationSymbol $_b = ',
            style: TextStyle(
              fontSize: questionFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          // 商答案框
          GestureDetector(
            onTap: () {
              setState(() {
                _currentAnswerField = 'quotient';
              });
              _requestFocus();
            },
            child: Container(
              width: answerBoxWidth,
              height: answerBoxHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _currentAnswerField == 'quotient'
                      ? Colors.blue
                      : Colors.grey,
                  width: _currentAnswerField == 'quotient' ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                readOnly: true,
                showCursor: false,
                controller: _answerController,
                focusNode: _answerFocus,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: inputFontSize,
                  fontWeight: FontWeight.bold,
                ),
                enableInteractiveSelection: false,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () {
                  setState(() {
                    _currentAnswerField = 'quotient';
                  });
                },
                onSubmitted: (_) => _switchToRemainderField(),
              ),
            ),
          ),
          Text(
            ' ... ',
            style: TextStyle(
              fontSize: questionFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          // 餘數答案框
          GestureDetector(
            onTap: () {
              setState(() {
                _currentAnswerField = 'remainder';
              });
              FocusScope.of(context).requestFocus(_remainderFocus);
            },
            child: Container(
              width: answerBoxWidth,
              height: answerBoxHeight,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _currentAnswerField == 'remainder'
                      ? Colors.blue
                      : Colors.grey,
                  width: _currentAnswerField == 'remainder' ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                readOnly: true,
                showCursor: false,
                controller: _remainderController,
                focusNode: _remainderFocus,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: inputFontSize,
                  fontWeight: FontWeight.bold,
                ),
                enableInteractiveSelection: false,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () {
                  setState(() {
                    _currentAnswerField = 'remainder';
                  });
                },
                onSubmitted: (_) => _checkAnswer(),
              ),
            ),
          ),
        ],
      );
    }

    // 其他運算：只顯示一個答案框
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$_a $_operationSymbol $_b = ',
          style: TextStyle(
            fontSize: questionFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          width: answerBoxWidth,
          height: answerBoxHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            readOnly: true,
            showCursor: false,
            controller: _answerController,
            focusNode: _answerFocus,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: inputFontSize,
              fontWeight: FontWeight.bold,
            ),
            enableInteractiveSelection: false,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: (_) => _checkAnswer(),
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeView(bool isTablet) {
    final double questionFontSize = isTablet ? 60 : 36;
    final double inputFontSize = isTablet ? 32 : 24;
    final double actionIconSize = _actionIconSize(isTablet);

    // 目前是第幾題（畫面顯示用：1-based，但不要超過總題數）
    final currentIndexForDisplay =
        (_answeredCount < _questionsPerSet) ? _answeredCount + 1 : _questionsPerSet;

    final progressValue =
        _questionsPerSet > 0 ? _answeredCount / _questionsPerSet : 0.0;

    return Column(
      children: [
        // 上方：進度 + 題目 + 輸入 + 訊息 + 數字鍵盤＋送出/清除
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

            // 題目和答案框（內嵌在一起）
            _buildQuestionWithAnswer(isTablet, questionFontSize, inputFontSize),
            const SizedBox(height: 12),

            // 數字鍵盤（總共兩行）
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 第一行：1, 2, 3, 4, 5, 送出
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int d = 1; d <= 5; d++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: _buildDigitKey(d, isTablet),
                      ),
                    // 送出（用你的 send.png）
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: _buildActionKey(
                        isTablet: isTablet,
                        tooltip: '送出答案',
                        onTap: _checkAnswer,
                        icon: ImageLoader.loadIcon(
                          iconName: 'send.png',
                          width: actionIconSize,
                          height: actionIconSize,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 第二行：6, 7, 8, 9, 0, 清除
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int d = 6; d <= 9; d++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: _buildDigitKey(d, isTablet),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: _buildDigitKey(0, isTablet),
                    ),
                    // 清除答案（用你的 eraser.png）
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: _buildActionKey(
                        isTablet: isTablet,
                        tooltip: '清除答案',
                        onTap: _clearAnswerField,
                        icon: ImageLoader.loadIcon(
                          iconName: 'eraser.png',
                          width: actionIconSize,
                          height: actionIconSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (_message.isNotEmpty)
              Text(
                _message,
                style: TextStyle(
                  fontSize: isTablet ? 36 : 18,
                  color: _messageColor,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),

        const SizedBox(height: 12),

        // 下方：手寫板區域（佔滿剩餘空間），右上角放清除筆跡按鈕
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
              child: Stack(
                children: [
                  GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _points.add(details.localPosition);
                      });
                    },
                    onPanUpdate: (details) {
                      final now = DateTime.now().millisecondsSinceEpoch;

                      // 1. 節流：限制大約 60fps 以內，不要每一個 event 都 setState
                      if (now - _lastPanUpdateMs < 16) {
                        return;
                      }
                      _lastPanUpdateMs = now;

                      final localPosition = details.localPosition;

                      // 2. 距離過近就不要再加點（減少 points 數量）
                      Offset? lastPoint;
                      for (int i = _points.length - 1; i >= 0; i--) {
                        final p = _points[i];
                        if (p != null) {
                          lastPoint = p;
                          break;
                        }
                      }

                      // 如果和上一個實際的點距離 < 2 像素，就忽略這次更新
                      if (lastPoint != null &&
                          (lastPoint - localPosition).distance < 2) {
                        return;
                      }

                      setState(() {
                        _points.add(localPosition);

                        // 3.（可選）限制最多保留的點數，避免一直累積到爆
                        const int maxPoints = 4000;
                        if (_points.length > maxPoints) {
                          final int removeCount = _points.length - maxPoints;
                          _points.removeRange(0, removeCount);
                        }
                      });
                    },
                    onPanEnd: (details) {
                      setState(() {
                        _points.add(null); // 分隔不同筆畫
                      });
                    },
                    child: RepaintBoundary( // ❹ 讓重繪範圍只在畫布
                      child: CustomPaint(
                        painter: HandwritingPainter(_points),
                        child: Container(), // 撐滿空間
                      ),
                    ),
                  ),


                  // 手寫區右上角的清除筆跡按鈕
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.white70,
                      shape: const CircleBorder(),
                      child: IconButton(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        icon: ImageLoader.loadIcon(
                          iconName: 'eraser.png',
                          width: isTablet ? 32 : 26,
                          height: isTablet ? 32 : 26,
                        ),
                        tooltip: '清除筆跡',
                        onPressed: _clearHandwriting,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

