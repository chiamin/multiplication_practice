part of 'multiplication_practice_page.dart';

/// 畫面 UI：設定畫面 + 練習畫面 + 手寫板 + 數字鍵盤
mixin MultiplicationPracticeUI
    on _MultiplicationPracticeBase, MultiplicationPracticeLogic {
  // === 鍵盤大小相關：這三個一起控制 ===
  double _keySize(bool isTablet) => isTablet ? 60 : 50; // 按鍵邊長
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
        title: Text(_inSettings ? '設定練習' : '算術練習'),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 24 : 12),
          child: _inSettings
              ? _buildSettingsView(isTablet)
              : _buildPracticeView(isTablet),
        ),
      ),
    );
  }

  Widget _buildOperationCardImage(Operation op, bool isTablet) {
    String asset;
    switch (op) {
      case Operation.add:
        asset = 'assets/add.png';
        break;
      case Operation.subtract:
        asset = 'assets/subtract.png';
        break;
      case Operation.multiply:
        asset = 'assets/multiply.png';
        break;
      case Operation.divide:
        asset = 'assets/divide.png';
        break;
    }

    return Image.asset(
      asset,
      width: isTablet ? 48 : 36,
      height: isTablet ? 48 : 36,
    );
  }

  Widget _buildNumberCard({
    required int value,
    required int selectedValue,
    required bool isTablet,
    required VoidCallback onTap,
  }) {
    final bool selected = value == selectedValue;
    final double size = isTablet ? 64 : 52;
    final double fontSize = isTablet ? 24 : 18;

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
          ),
          const SizedBox(height: 24),

          // 🔹 運算種類
          Text(
            '運算種類',
            style: TextStyle(fontSize: labelFontSize),
          ),
          const SizedBox(height: 8),
          Row(
            children: Operation.values.map((op) {
              final selected = _operation == op;
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
                    padding:
                        const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.blue.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? Colors.blue.shade400
                            : Colors.grey.shade400,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildOperationCardImage(op, isTablet),
                        const SizedBox(height: 4),
                        Text(
                          op.label,
                          style: TextStyle(
                            fontSize: isTablet ? 20 : 14,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // 🔹 位數設定
          Text(
            '第一個數字位數',
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

          Text(
            '第二個數字位數',
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

          const SizedBox(height: 24),

          // 🔹 手寫板開關
          Row(
            children: [
              Switch(
                value: _enableHandwriting,
                onChanged: (v) {
                  setState(() {
                    _enableHandwriting = v;
                  });
                },
              ),
              const SizedBox(width: 8),
              Text(
                '使用手寫板輸入',
                style: TextStyle(fontSize: labelFontSize),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // 開始練習按鈕
          Center(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _answeredCount = 0;
                  _inSettings = false;
                });
                _generateNewQuestion();
                _requestFocus();
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Text(
                  '開始練習',
                  style: TextStyle(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDigitKey({
    required String digit,
    required bool isTablet,
  }) {
    final double size = _keySize(isTablet);

    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _answerController.text += digit;
          });
          _requestFocus();
        },
        child: Text(
          digit,
          style: TextStyle(
            fontSize: _digitFontSize(isTablet),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required bool isTablet,
  }) {
    final double size = _keySize(isTablet);
    final double iconSize = _actionIconSize(isTablet);

    return SizedBox(
      width: size,
      height: size,
      child: Tooltip(
        message: tooltip,
        child: ElevatedButton(
          onPressed: onPressed,
          child: Icon(
            icon,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeView(bool isTablet) {
    final double questionFontSize = isTablet ? 60 : 36;
    final double inputFontSize = isTablet ? 32 : 24;

    // 目前是第幾題（畫面顯示用：1-based，但不要超過總題數）
    final currentIndexForDisplay =
        (_answeredCount < _questionsPerSet) ? _answeredCount + 1 : _questionsPerSet;

    final progressValue =
        _questionsPerSet > 0 ? _answeredCount / _questionsPerSet : 0.0;

    return Column(
      children: [
        // 上方：進度 + 題目 + 輸入 + 訊息 + 數字鍵盤＋送出/清除
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 進度條
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
            const SizedBox(height: 16),

            // 題目（a op b = ?）
            Center(
              child: Text(
                '$_a $_operationSymbol $_b = ?',
                style: TextStyle(
                  fontSize: questionFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 答案輸入框
            Center(
              child: SizedBox(
                width: isTablet ? 260 : 200,
                child: TextField(
                  controller: _answerController,
                  focusNode: _answerFocus,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: inputFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  onSubmitted: (_) => _checkAnswer(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '在這裡輸入答案',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 提示訊息
            if (_message.isNotEmpty)
              Center(
                child: Text(
                  _message,
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 16,
                    color: _messageColor,
                  ),
                ),
              ),
            if (_message.isNotEmpty) const SizedBox(height: 12),

            // 數字鍵盤 + 送出/清除
            Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (var d in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'])
                    _buildDigitKey(
                      digit: d,
                      isTablet: isTablet,
                    ),
                  _buildActionKey(
                    icon: Icons.backspace,
                    tooltip: '清除答案',
                    onPressed: _clearAnswerField,
                    isTablet: isTablet,
                  ),
                  _buildActionKey(
                    icon: Icons.check,
                    tooltip: '送出答案',
                    onPressed: _checkAnswer,
                    isTablet: isTablet,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 下方：手寫板（可選）
        if (_enableHandwriting)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '手寫板',
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                      color: Colors.white,
                    ),
                    child: Stack(
                      children: [
                        GestureDetector(
                          onPanStart: (details) {
                            final box =
                                context.findRenderObject() as RenderBox;
                            final localPos =
                                box.globalToLocal(details.globalPosition);
                            setState(() {
                              _points.add(localPos);
                            });
                          },
                          onPanUpdate: (details) {
                            final nowMs =
                                DateTime.now().millisecondsSinceEpoch;
                            if (nowMs - _lastPanUpdateMs < 8) {
                              return;
                            }
                            _lastPanUpdateMs = nowMs;

                            final box =
                                context.findRenderObject() as RenderBox;
                            final localPos =
                                box.globalToLocal(details.globalPosition);
                            setState(() {
                              _points.add(localPos);

                              // 限制最多保留的點數，避免一直累積到爆
                              const int maxPoints = 4000;
                              if (_points.length > maxPoints) {
                                final int removeCount =
                                    _points.length - maxPoints;
                                _points.removeRange(0, removeCount);
                              }
                            });
                          },
                          onPanEnd: (_) {
                            setState(() {
                              _points.add(null); // 分隔不同筆畫
                            });
                          },
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: HandwritingPainter(
                                points: _points,
                                strokeWidth: _strokeWidth,
                              ),
                              child: Container(), // 撐滿空間
                            ),
                          ),
                        ),

                        // 手寫區右上角的清除筆跡按鈕
                        Positioned(
                          right: 8,
                          top: 8,
                          child: IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: '清除筆跡',
                            onPressed: _clearHandwriting,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

