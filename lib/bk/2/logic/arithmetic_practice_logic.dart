import 'dart:math';
import '../models/operation.dart';
import '../models/question.dart';

/// 純邏輯：負責出題 & 計算答案
class ArithmeticPracticeLogic {
  final Random _random = Random();

  /// 依照位數產生亂數
  int _randomNumberWithDigits(int digits) {
    if (digits <= 1) {
      return 2 + _random.nextInt(8); // 2~9
    }

    final int min = pow(10, digits - 1).toInt();
    final int max = pow(10, digits).toInt() - 1;
    return min + _random.nextInt(max - min + 1);
  }

  /// 產生一題
  Question generateQuestion({
    required Operation operation,
    required int digitsA,
    required int digitsB,
  }) {
    switch (operation) {
      case Operation.add:
        return Question(
          a: _randomNumberWithDigits(digitsA)_

