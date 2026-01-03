import 'dart:math';
import '../models/operation.dart';

/// 題目生成器 - 獨立於 UI 的核心邏輯
class QuestionGenerator {
  final Random _random;

  QuestionGenerator({Random? random}) : _random = random ?? Random();

  /// 從範圍中產生亂數
  int randomNumberInRange(int min, int max) {
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

  /// 生成加法題目
  ({int a, int b}) generateAddition({
    required int minA,
    required int maxA,
    required int minB,
    required int maxB,
  }) {
    return (
      a: randomNumberInRange(minA, maxA),
      b: randomNumberInRange(minB, maxB),
    );
  }

  /// 生成減法題目（確保 a >= b，避免負數）
  ({int a, int b}) generateSubtraction({
    required int minA,
    required int maxA,
    required int minB,
    required int maxB,
  }) {
    final b = randomNumberInRange(minB, maxB);
    final effectiveMinA = (minA > b) ? minA : b;
    
    if (effectiveMinA > maxA) {
      // 如果範圍A的最大值都小於範圍B的值，無法生成有效題目
      // 退而求其次：讓 a 盡量大，b 盡量小（但仍在各自範圍內）
      final a = maxA;
      final maxBForA = (a < maxB) ? a : maxB;
      final adjustedB = (minB <= maxBForA) ? minB : maxBForA;
      return (a: a, b: adjustedB);
    } else {
      final a = randomNumberInRange(effectiveMinA, maxA);
      return (a: a, b: b);
    }
  }

  /// 生成乘法題目
  ({int a, int b}) generateMultiplication({
    required int minA,
    required int maxA,
    required int minB,
    required int maxB,
  }) {
    return (
      a: randomNumberInRange(minA, maxA),
      b: randomNumberInRange(minB, maxB),
    );
  }

  /// 生成除法題目（可以有餘數）
  ({int a, int b}) generateDivision({
    required int minA,
    required int maxA,
    required int minB,
    required int maxB,
  }) {
    const int maxTries = 1000;
    
    // 方法1：先選 b，再計算商的範圍
    for (int i = 0; i < maxTries; i++) {
      final b = randomNumberInRange(minB, maxB);
      
      // 根據範圍計算商的合理範圍
      // a = b * q + r，其中 0 <= r < b
      final numerator = minA - (b - 1);
      final minQ = (numerator <= 0) 
          ? 1 
          : ((numerator + b - 1) ~/ b).clamp(1, 999);
      final maxQ = (maxA ~/ b).clamp(1, 999);
      
      if (minQ > maxQ) {
        continue;
      }
      
      final q = randomNumberInRange(minQ, maxQ);
      final r = _random.nextInt(b); // 餘數：0 到 b-1
      final a = b * q + r;
      
      if (a >= minA && a <= maxA) {
        return (a: a, b: b);
      }
    }

    // 方法2：反向生成：先選 a，再選 b
    for (int i = 0; i < maxTries; i++) {
      final a = randomNumberInRange(minA, maxA);
      final maxBForA = (maxB < a) ? maxB : a;
      if (maxBForA < minB) {
        continue;
      }
      final b = randomNumberInRange(minB, maxBForA);
      
      if (a >= minA && a <= maxA && b >= minB && b <= maxB) {
        return (a: a, b: b);
      }
    }

    // 最後的 fallback：確保 a 和 b 都在各自範圍內，且 a >= b
    final a = minA.clamp(minA, maxA);
    final b = minB.clamp(minB, maxB);
    final adjustedA = (a < b) ? b.clamp(minA, maxA) : a;
    return (a: adjustedA, b: b);
  }

  /// 根據運算類型生成題目
  ({int a, int b}) generateQuestion({
    required Operation operation,
    required int minA,
    required int maxA,
    required int minB,
    required int maxB,
  }) {
    return switch (operation) {
      Operation.add => generateAddition(
          minA: minA, maxA: maxA, minB: minB, maxB: maxB),
      Operation.subtract => generateSubtraction(
          minA: minA, maxA: maxA, minB: minB, maxB: maxB),
      Operation.multiply => generateMultiplication(
          minA: minA, maxA: maxA, minB: minB, maxB: maxB),
      Operation.divide => generateDivision(
          minA: minA, maxA: maxA, minB: minB, maxB: maxB),
    };
  }
}

/// 答案檢查器 - 獨立於 UI 的核心邏輯
class AnswerChecker {
  /// 計算正確答案
  int calculateCorrectAnswer({
    required Operation operation,
    required int a,
    required int b,
  }) {
    return switch (operation) {
      Operation.add => a + b,
      Operation.subtract => a - b,
      Operation.multiply => a * b,
      Operation.divide => throw ArgumentError('除法請使用 checkDivisionAnswer'),
    };
  }

  /// 檢查除法答案
  ({bool isCorrect, String? errorMessage}) checkDivisionAnswer({
    required int a,
    required int b,
    required int quotient,
    required int remainder,
  }) {
    // 檢查餘數是否小於除數
    if (remainder >= b) {
      return (
        isCorrect: false,
        errorMessage: '餘數應該小於除數喔',
      );
    }

    final correctQuotient = a ~/ b;
    final correctRemainder = a % b;

    if (quotient == correctQuotient && remainder == correctRemainder) {
      return (isCorrect: true, errorMessage: null);
    } else {
      return (isCorrect: false, errorMessage: null);
    }
  }

  /// 檢查答案（非除法）
  bool checkAnswer({
    required Operation operation,
    required int a,
    required int b,
    required int userAnswer,
  }) {
    final correct = calculateCorrectAnswer(
      operation: operation,
      a: a,
      b: b,
    );
    return userAnswer == correct;
  }
}

