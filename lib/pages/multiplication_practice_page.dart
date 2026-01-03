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

  // 設定：第一個數字的範圍
  final TextEditingController _minAController = TextEditingController(text: '1');
  final TextEditingController _maxAController = TextEditingController(text: '9');
  // 設定：第二個數字的範圍
  final TextEditingController _minBController = TextEditingController(text: '1');
  final TextEditingController _maxBController = TextEditingController(text: '9');

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

  /// 播放音效
  Future<void> _playSound(String soundFile) async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/$soundFile'));
    } catch (e) {
      debugPrint('播放音效錯誤: $e');
    }
  }

  /// 設定訊息
  void _setMessage(String message, Color color) {
    setState(() {
      _message = message;
      _messageColor = color;
    });
  }

  /// 清除訊息
  void _clearMessage() {
    setState(() {
      _message = '';
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocus.dispose();
    _remainderController.dispose();
    _remainderFocus.dispose();
    _minAController.dispose();
    _maxAController.dispose();
    _minBController.dispose();
    _maxBController.dispose();
    _player.dispose();
    super.dispose();
  }

  /// 從範圍中產生亂數
  int _randomNumberInRange(int min, int max) {
    if (min > max) {
      // 如果最小值大於最大值，交換它們
      final temp = min;
      min = max;
      max = temp;
    }
    if (min == max) {
      return min;
    }
    return min + _random.nextInt(max - min + 1);
  }

  /// 獲取第一個數字的範圍（帶驗證）
  (int min, int max) _getRangeA() {
    final minA = int.tryParse(_minAController.text.trim()) ?? 1;
    final maxA = int.tryParse(_maxAController.text.trim()) ?? 9;
    return (minA, maxA);
  }

  /// 獲取第二個數字的範圍（帶驗證）
  (int min, int max) _getRangeB() {
    final minB = int.tryParse(_minBController.text.trim()) ?? 1;
    final maxB = int.tryParse(_maxBController.text.trim()) ?? 9;
    return (minB, maxB);
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
      final (minA, maxA) = _getRangeA();
      final (minB, maxB) = _getRangeB();

      switch (_operation) {
        case Operation.add:
          _a = _randomNumberInRange(minA, maxA);
          _b = _randomNumberInRange(minB, maxB);
          break;
        case Operation.subtract:
          // 減法：確保 _a >= _b（避免負數），同時 _a 在範圍A，_b 在範圍B
          // 先選 _b（從範圍B），然後選 _a（從範圍A，但確保 _a >= _b）
          _b = _randomNumberInRange(minB, maxB);
          final int effectiveMinA = (minA > _b) ? minA : _b;
          if (effectiveMinA > maxA) {
            // 如果範圍A的最大值都小於範圍B的值，無法生成有效題目
            // 退而求其次：讓 _a 盡量大，_b 盡量小（但仍在各自範圍內）
            _a = maxA;
            _b = minB.clamp(minB, (_a < maxB) ? _a : maxB);
          } else {
            _a = _randomNumberInRange(effectiveMinA, maxA);
          }
          break;
        case Operation.multiply:
          _a = _randomNumberInRange(minA, maxA);
          _b = _randomNumberInRange(minB, maxB);
          break;
        case Operation.divide:
          _generateDivisionQuestion();
          break;
      }

      _answerController.clear();
      _remainderController.clear();
      _clearMessage();
      _currentAnswerField = 'quotient'; // 重置為商
      _points.clear(); // 換題時把手寫板也清掉
    });
  }

  /// 產生除法題目（可以有餘數）
  void _generateDivisionQuestion() {
    final (minA, maxA) = _getRangeA();
    final (minB, maxB) = _getRangeB();

    const int maxTries = 1000;
    for (int i = 0; i < maxTries; i++) {
      final int b = _randomNumberInRange(minB, maxB);
      
      // 根據範圍計算商的合理範圍
      // a = b * q + r，其中 0 <= r < b
      // 所以：b * q <= a < b * (q + 1)
      // 要讓 a 在 [minA, maxA] 範圍內，需要：
      // minA <= b * q + r <= maxA，其中 r < b
      // 因此：minA <= b * q + (b-1) 且 b * q <= maxA
      // 所以：q >= ceil((minA - (b-1)) / b) 且 q <= floor(maxA / b)
      
      // 計算商的最小值：為了讓 a >= minA，需要 b * q >= minA - (b-1)
      // 但考慮餘數最大是 b-1，所以 b * q 至少要是 minA - (b-1)
      // 使用 ceil 計算：ceil((minA - (b-1)) / b)，但確保至少是 1
      final int numerator = minA - (b - 1);
      final int minQ = (numerator <= 0) 
          ? 1 
          : ((numerator + b - 1) ~/ b).clamp(1, 999); // ceil 的實現：(x + b - 1) ~/ b
      // 計算商的最大值：為了讓 a <= maxA，需要 b * q <= maxA（因為 r >= 0）
      final int maxQ = (maxA ~/ b).clamp(1, 999);
      
      // 如果沒有合理的商範圍，跳過這次嘗試
      if (minQ > maxQ) {
        continue;
      }
      
      final int q = _randomNumberInRange(minQ, maxQ);
      final int r = _random.nextInt(b); // 餘數：0 到 b-1
      final int a = b * q + r;
      
      // 再次確認 a 在範圍內（應該總是符合，但為了安全還是檢查）
      if (a >= minA && a <= maxA) {
        _a = a;
        _b = b;
        return;
      }
    }

    // 如果上面實在找不到符合範圍的，嘗試反向生成：先選 a，再選 b
    for (int i = 0; i < maxTries; i++) {
      final int a = _randomNumberInRange(minA, maxA);
      // 確保 b <= a（這樣商至少是 1），且 b 在範圍B內
      final int maxBForA = (maxB < a) ? maxB : a;
      if (maxBForA < minB) {
        continue; // 無法找到符合條件的 b
      }
      final int b = _randomNumberInRange(minB, maxBForA);
      
      // 再次確認 a 和 b 都在各自範圍內（應該總是符合）
      if (a >= minA && a <= maxA && b >= minB && b <= maxB) {
        _a = a;
        _b = b;
        return;
      }
    }

    // 最後的 fallback：確保 _a 和 _b 都在各自範圍內，且 _a >= _b
    _a = minA.clamp(minA, maxA);
    _b = minB.clamp(minB, maxB);
    // 確保 _a >= _b
    if (_a < _b) {
      _a = _b.clamp(minA, maxA);
    }
  }

  Future<void> _checkAnswer() async {
    // 除法需要檢查商和餘數
    if (_operation == Operation.divide) {
      final quotientText = _answerController.text.trim();
      final remainderText = _remainderController.text.trim();
      
      if (quotientText.isEmpty || remainderText.isEmpty) {
        _setMessage('請輸入商和餘數', Colors.orange);
        return;
      }

      final int? quotient = int.tryParse(quotientText);
      final int? remainder = int.tryParse(remainderText);
      
      if (quotient == null || remainder == null) {
        _setMessage('請輸入整數喔', Colors.orange);
        return;
      }

      // 檢查餘數是否小於除數
      if (remainder >= _b) {
        _setMessage('餘數應該小於除數喔', Colors.orange);
        return;
      }

      final int correctQuotient = _a ~/ _b;
      final int correctRemainder = _a % _b;

      if (quotient == correctQuotient && remainder == correctRemainder) {
        _setMessage('答對了！太棒了 🎉', Colors.green);
        await _playSound('ding.mp3');
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
        await _playSound('eoh.mp3');
        _requestFocus();
      }
      return;
    }

    // 其他運算（加、減、乘）
    final text = _answerController.text.trim();
    if (text.isEmpty) {
      _setMessage('請先輸入答案', Colors.orange);
      return;
    }

    final int? value = int.tryParse(text);
    if (value == null) {
      _setMessage('請輸入整數喔', Colors.orange);
      return;
    }

    // 根據運算種類計算正確答案
    final int correct = switch (_operation) {
      Operation.add => _a + _b,
      Operation.subtract => _a - _b,
      Operation.multiply => _a * _b,
      Operation.divide => throw StateError('除法應該在上面已經處理'),
    };

    if (value == correct) {
      _setMessage('答對了！太棒了 🎉', Colors.green);
      await _playSound('ding.mp3');
      await Future.delayed(const Duration(milliseconds: 1000));
      await _onQuestionFinished();
    } else {
      final wrong = _answerController.text; // 記住錯誤答案（原樣）
      setState(() {
        _message = '不是 $wrong 喔，再試試 🙈';
        _messageColor = Colors.red;
        _answerController.clear(); // 清掉輸入框，讓下一次輸入直接重打
      });
      await _playSound('eoh.mp3');
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

    debugPrint('🎉 開始顯示慶祝動畫，已完成題數: $_answeredCount / $_questionsPerSet');

    // 在這裡重新計算 isTablet
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.shortestSide >= 600;

    // 1. 先顯示慶祝動畫（兔子 + cheer 音效）
    // 不 await showDialog，因為它會在 dialog 關閉時才完成
    // 我們需要立即繼續執行，等待4秒後再關閉
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,       // 背景保持透明
      useRootNavigator: true,
      builder: (_) {
        debugPrint('🎬 正在構建 RabbitsCelebration widget');
        return RabbitsCelebration(isTablet: isTablet);
      },
    );

    // 2. 等待一幀，確保 dialog 已經顯示
    // 使用 SchedulerBinding 確保下一幀已經渲染
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    if (!mounted) return;
    
    debugPrint('⏳ 等待動畫播放 4 秒...');

    // 3. 等待動畫播完（4秒）
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    // 4. 安全地關掉慶祝動畫的 dialog
    debugPrint('🔚 準備關閉慶祝動畫 dialog');
    try {
      // 檢查 dialog 是否還在顯示
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
        debugPrint('✅ 慶祝動畫 dialog 已關閉');
      } else {
        debugPrint('⚠️ 無法關閉 dialog，可能已經關閉');
      }
      // 確保 dialog 完全關閉
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('❌ 關閉慶祝動畫 dialog 錯誤: $e');
    }

    if (!mounted) return;

    // 5. 再顯示「本次練習完成」的選項對話框
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
      });
      _clearMessage();
      _generateNewQuestion();
      _requestFocus();
    } else {
      // 回到設定頁
      setState(() {
        _inSettings = true;
      });
      _clearMessage();
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

  // 範圍輸入框（最小值～最大值）
  Widget _buildRangeInput({
    required TextEditingController minController,
    required TextEditingController maxController,
    required String label,
    required bool isTablet,
  }) {
    final double fontSize = isTablet ? 24 : 18;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: fontSize),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '最小值',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: TextStyle(fontSize: fontSize),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '~',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '最大值',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                style: TextStyle(fontSize: fontSize),
              ),
            ),
          ],
        ),
      ],
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

          // 🔹 第一個數字的範圍
          _buildRangeInput(
            minController: _minAController,
            maxController: _maxAController,
            label: '第一個數字的範圍',
            isTablet: isTablet,
          ),

          const SizedBox(height: 24),

          // 🔹 第二個數字的範圍
          _buildRangeInput(
            minController: _minBController,
            maxController: _maxBController,
            label: '第二個數字的範圍',
            isTablet: isTablet,
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

  /// 將數字追加到指定的控制器
  void _appendDigitToController(TextEditingController controller, int digit) {
    controller.text = controller.text + digit.toString();
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
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
          if (_operation == Operation.divide && _currentAnswerField == 'remainder') {
            _appendDigitToController(_remainderController, digit);
          } else {
            _appendDigitToController(_answerController, digit);
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

  /// 建立答案框的 TextField
  Widget _buildAnswerTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required double fontSize,
    required VoidCallback? onTap,
    required VoidCallback? onSubmitted,
  }) {
    return TextField(
      readOnly: true,
      showCursor: false,
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
      ),
      enableInteractiveSelection: false,
      decoration: const InputDecoration(
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      onTap: onTap,
      onSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
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
              child: _buildAnswerTextField(
                controller: _answerController,
                focusNode: _answerFocus,
                fontSize: inputFontSize,
                onTap: () {
                  setState(() {
                    _currentAnswerField = 'quotient';
                  });
                },
                onSubmitted: _switchToRemainderField,
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
              child: _buildAnswerTextField(
                controller: _remainderController,
                focusNode: _remainderFocus,
                fontSize: inputFontSize,
                onTap: () {
                  setState(() {
                    _currentAnswerField = 'remainder';
                  });
                },
                onSubmitted: _checkAnswer,
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
          child: _buildAnswerTextField(
            controller: _answerController,
            focusNode: _answerFocus,
            fontSize: inputFontSize,
            onTap: null,
            onSubmitted: _checkAnswer,
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

