import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/operation.dart';
import '../widgets/handwriting_painter.dart';
import '../logic/arithmetic_practice_logic.dart';

/// 主畫面：包含「設定練習」與「實際練習」兩個畫面
class MultiplicationPracticePage extends StatefulWidget {
  const MultiplicationPracticePage({super.key});

  @override
  State<MultiplicationPracticePage> createState() =>
      _MultiplicationPracticePageState();
}

class _MultiplicationPracticePageState
    extends State<MultiplicationPracticePage> {
  // 出題與計算正確答案的「純邏輯」物件
  final ArithmeticPracticeLogic _logic = ArithmeticPracticeLogic();

  // 使用者輸入答案的文字框
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _answerFocus = FocusNode();

  // 當前題目的兩個數字
  late int _a;
  late int _b;

  // 顯示答對／答錯的訊息
  String _message = '';
  Color _messageColor = Colors.black;

  // 音效播放器（播放答對 ding.mp3）
  final AudioPlayer _player = AudioPlayer();

  // ========= 設定區 =========

  // 第一個數字的位數（1~9）
  int _digitsA = 1;

  // 第二個數字的位數（1~9）
  int _digitsB = 1;

  // 一組要練習幾題
  int _questionsPerSet = 10;

  // 本組已作答的題數（答對才會 +1）
  int _answeredCount = 0;

  // 現在選擇的運算種類（預設：乘法）
  Operation _operation = Operation.multiply;

  // 是否目前在「設定頁」
  bool _inSettings = true;

  // 手寫區的軌跡點（null 代表分隔不同筆畫）
  final List<Offset?> _points = [];

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocus.dispose();
    _player.dispose();
    super.dispose();
  }

  /// 目前運算的符號，只是顯示用
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

  // ============= 出新題目（用邏輯物件） =============

  void _generateNewQuestion() {
    setState(() {
      final question = _logic.generateQuestion(
        operation: _operation,
        digitsA: _digitsA,
        digitsB: _digitsB,
      );

      _a = question.a;
      _b = question.b;

      _answerController.clear();
      _message = '';
      _points.clear(); // 換題時順便把手寫板清掉
    });
  }

  // ============= 檢查答案 =============

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

    // 用邏輯物件計算正確答案（UI 不自己算）
    final int correct = _logic.calculateCorrectAnswer(
      _operation,
      _a,
      _b,
    );

    if (value == correct) {
      // 答對
      setState(() {
        _message = '答對了！太棒了 🎉';
        _messageColor = Colors.green;
      });

      // 播放答對音效
      try {
        await _player.play(AssetSource('sounds/ding.mp3'));
      } catch (e) {
        debugPrint('播放音效錯誤: $e');
      }

      // 稍微停一下再進下一題或結束
      await Future.delayed(const Duration(milliseconds: 600));
      await _onQuestionFinished();
    } else {
      // 答錯，不顯示正解
      setState(() {
        _message = '答錯了，再試試 🙈';
        _messageColor = Colors.red;
      });

      // 全選文字，方便重新輸入
      _answerController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _answerController.text.length,
      );
      _requestFocus();
    }
  }

  /// 把輸入焦點放回答案輸入框
  void _requestFocus() {
    FocusScope.of(context).requestFocus(_answerFocus);
  }

  // 一題結束（通常是答對後）要做的事
  Future<void> _onQuestionFinished() async {
    setState(() {
      _answeredCount++;
    });

    if (_answeredCount >= _questionsPerSet) {
      // 本組題目完成
      await _showSessionCompletedDialog();
    } else {
      // 還有題目 → 出下一題
      _generateNewQuestion();
      _requestFocus();
    }
  }

  /// 清除手寫板
  void _clearHandwriting() {
    setState(() {
      _points.clear();
    });
  }

  /// 清除答案欄（不換題）
  void _clearAnswerField() {
    setState(() {
      _answerController.clear();
    });
    _requestFocus();
  }

  // 顯示「本次練習完成」對話框
  Future<void> _showSessionCompletedDialog() async {
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // 不允許點外面關閉
      builder: (context) => AlertDialog(
        title: const Text('本次練習完成'),
        content: Text('你已完成 $_questionsPerSet 題練習，要再做一組嗎？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false); // 回設定頁
            },
            child: const Text('回到設定'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true); // 再做一組
            },
            child: const Text('再做一組',
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result == true) {
      // 再做一組：保留目前設定，只重置進度與訊息
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

  // ================= Scaffold 外框 =================

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
        title: Text(_inSettings ? '設定練習' : '算術練習'),
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

  // ================= 設定畫面 =================

  /// 四則運算卡片（用你下載的 icon）
  Widget _buildOperationCardImage(
    Operation op,
    String assetPath,
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
              Image.asset(
                assetPath,
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

  /// 共用：數字小卡片（位數、題數選擇）
  Widget _buildNumberCard({
    required int value,
    required int selectedValue,
    required bool isTablet,
    required VoidCallback onTap,
  }) {
    final bool selected = value == selectedValue;
    final double fontSize = isTablet ? 22 : 16;
    final double size = isTablet ? 52 : 40;

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

  /// 「設定頁」內容
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

          // 四則運算選擇（使用你的加減乘除圖示）
          Text(
            '要練習的運算',
            style: TextStyle(fontSize: labelFontSize),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildOperationCardImage(
                Operation.add,
                'assets/icons/add.png',
                '加法',
                isTablet,
              ),
              _buildOperationCardImage(
                Operation.subtract,
                'assets/icons/subtract.png',
                '減法',
                isTablet,
              ),
              _buildOperationCardImage(
                Operation.multiply,
                'assets/icons/multiply.png',
                '乘法',
                isTablet,
              ),
              _buildOperationCardImage(
                Operation.divide,
                'assets/icons/divide.png',
                '除法',
                isTablet,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 第一個數字的位數
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

          // 第二個數字的位數
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

          // 一次要練習幾題
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

          // 開始練習按鈕
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

  // ================= 練習畫面 =================

  /// 數字鍵盤的單一數字按鍵（0~9）
  Widget _buildDigitKey(int digit, bool isTablet) {
    final double size = isTablet ? 52 : 40;
    final double fontSize = isTablet ? 24 : 18;

    return InkWell(
      onTap: () {
        setState(() {
          _answerController.text =
              _answerController.text + digit.toString();
          _answerController.selection = TextSelection.fromPosition(
            TextPosition(offset: _answerController.text.length),
          );
        });
        _requestFocus();
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

  /// 行為按鍵（送出 / 清除答案）與數字鍵相同尺寸
  Widget _buildActionKey({
    required bool isTablet,
    required Widget icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final double size = isTablet ? 52 : 40;

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

  /// 「練習頁」內容
  Widget _buildPracticeView(bool isTablet) {
    final double questionFontSize = isTablet ? 60 : 36;
    final double inputFontSize = isTablet ? 32 : 24;

    // 顯示用的題號（1-based）
    final currentIndexForDisplay = (_answeredCount < _questionsPerSet)
        ? _answeredCount + 1
        : _questionsPerSet;

    final progressValue = _questionsPerSet > 0
        ? _answeredCount / _questionsPerSet
        : 0.0;

    return Column(
      children: [
        // 上半部：進度列 + 題目 + 輸入 + 數字鍵 + 訊息
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

            // 題目
            Text(
              '$_a $_operationSymbol $_b = ?',
              style: TextStyle(
                fontSize: questionFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 答案輸入框
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

            // 數字鍵盤 0~9 + 送出 + 清除答案
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (int d = 1; d <= 9; d++) _buildDigitKey(d, isTablet),
                _buildDigitKey(0, isTablet),

                // 送出答案（紙飛機）
                _buildActionKey(
                  isTablet: isTablet,
                  tooltip: '送出答案',
                  onTap: _checkAnswer,
                  icon: Image.asset(
                    'assets/icons/send.png',
                    width: isTablet ? 28 : 22,
                    height: isTablet ? 28 : 22,
                  ),
                ),

                // 清除答案（橡皮擦）
                _buildActionKey(
                  isTablet: isTablet,
                  tooltip: '清除答案',
                  onTap: _clearAnswerField,
                  icon: Image.asset(
                    'assets/icons/eraser.png',
                    width: isTablet ? 28 : 22,
                    height: isTablet ? 28 : 22,
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

        // 下半部：手寫板
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

                  // 手寫區右上角的「清除筆跡」按鈕
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.white70,
                      shape: const CircleBorder(),
                      child: IconButton(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.cleaning_services,
                          size: isTablet ? 26 : 22,
                          color: Colors.brown,
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

