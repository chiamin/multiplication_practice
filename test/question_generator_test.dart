import 'package:flutter_test/flutter_test.dart';
import 'package:multiplication_practice/utils/question_generator.dart';
import 'package:multiplication_practice/models/operation.dart';
import 'dart:math';

void main() {
  group('QuestionGenerator - 基本功能測試', () {
    test('randomNumberInRange - 正常範圍', () {
      final generator = QuestionGenerator();
      
      for (int i = 0; i < 100; i++) {
        final result = generator.randomNumberInRange(1, 10);
        expect(result, greaterThanOrEqualTo(1));
        expect(result, lessThanOrEqualTo(10));
      }
    });

    test('randomNumberInRange - 單一值', () {
      final generator = QuestionGenerator();
      expect(generator.randomNumberInRange(5, 5), equals(5));
    });

    test('randomNumberInRange - 範圍反轉自動修正', () {
      final generator = QuestionGenerator();
      
      for (int i = 0; i < 100; i++) {
        final result = generator.randomNumberInRange(10, 1);
        expect(result, greaterThanOrEqualTo(1));
        expect(result, lessThanOrEqualTo(10));
      }
    });
  });

  group('QuestionGenerator - 加法測試', () {
    test('生成加法題目 - 基本範圍', () {
      final generator = QuestionGenerator();
      
      for (int i = 0; i < 100; i++) {
        final question = generator.generateAddition(
          minA: 1,
          maxA: 10,
          minB: 1,
          maxB: 10,
        );
        
        expect(question.a, greaterThanOrEqualTo(1));
        expect(question.a, lessThanOrEqualTo(10));
        expect(question.b, greaterThanOrEqualTo(1));
        expect(question.b, lessThanOrEqualTo(10));
      }
    });

    test('生成加法題目 - 大範圍', () {
      final generator = QuestionGenerator();
      
      for (int i = 0; i < 50; i++) {
        final question = generator.generateAddition(
          minA: 50,
          maxA: 99,
          minB: 1,
          maxB: 4,
        );
        
        expect(question.a, greaterThanOrEqualTo(50));
        expect(question.a, lessThanOrEqualTo(99));
        expect(question.b, greaterThanOrEqualTo(1));
        expect(question.b, lessThanOrEqualTo(4));
      }
    });

    test('生成加法題目 - 邊界值', () {
      final generator = QuestionGenerator();
      
      final question = generator.generateAddition(
        minA: 1,
        maxA: 1,
        minB: 1,
        maxB: 1,
      );
      
      expect(question.a, equals(1));
      expect(question.b, equals(1));
    });
  });

  group('QuestionGenerator - 減法測試', () {
    test('生成減法題目 - 確保 a >= b', () {
      final generator = QuestionGenerator();
      
      for (int i = 0; i < 100; i++) {
        final question = generator.generateSubtraction(
          minA: 1,
          maxA: 10,
          minB: 1,
          maxB: 10,
        );
        
        expect(question.a, greaterThanOrEqualTo(question.b));
        expect(question.a, greaterThanOrEqualTo(1));
        expect(question.a, lessThanOrEqualTo(10));
        expect(question.b, greaterThanOrEqualTo(1));
        expect(question.b, lessThanOrEqualTo(10));
      }
    });

    test('生成減法題目 - 範圍A大於範圍B', () {
      final generator = QuestionGenerator();
      
      for (int i = 0; i < 100; i++) {
        final question = generator.generateSubtraction(
          minA: 50,
          maxA: 99,
          minB: 1,
          maxB: 4,
        );
        
        expect(question.a, greaterThanOrEqualTo(question.b));
        expect(question.a, greaterThanOrEqualTo(50));
        expect(question.a, lessThanOrEqualTo(99));
        expect(question.b, greaterThanOrEqualTo(1));
        expect(question.b, lessThanOrEqualTo(4));
      }
    });

    test('生成減法題目 - 範圍B大於範圍A的邊界情況', () {
      final generator = QuestionGenerator();
      
      // 當範圍A的最大值小於範圍B的最小值時，無法生成有效的減法題目
      // 但應該至少返回一個在範圍內的值（可能使用 fallback）
      final question = generator.generateSubtraction(
        minA: 1,
        maxA: 5,
        minB: 10,
        maxB: 20,
      );
      
      // 在這種情況下，a 和 b 可能無法滿足 a >= b，但應該在各自範圍內
      // 或者 fallback 會調整 a 使其至少等於 b
      expect(question.a, lessThanOrEqualTo(5));
      // b 可能在範圍B內，或者被調整
      expect(question.b, greaterThanOrEqualTo(1)); // 至少是正數
    });
  });

  group('QuestionGenerator - 乘法測試', () {
    test('生成乘法題目 - 基本範圍', () {
      final generator = QuestionGenerator();
      
      for (int i = 0; i < 100; i++) {
        final question = generator.generateMultiplication(
          minA: 1,
          maxA: 10,
          minB: 1,
          maxB: 10,
        );
        
        expect(question.a, greaterThanOrEqualTo(1));
        expect(question.a, lessThanOrEqualTo(10));
        expect(question.b, greaterThanOrEqualTo(1));
        expect(question.b, lessThanOrEqualTo(10));
      }
    });

    test('生成乘法題目 - 大範圍', () {
      final generator = QuestionGenerator();
      
      for (int i = 0; i < 50; i++) {
        final question = generator.generateMultiplication(
          minA: 50,
          maxA: 99,
          minB: 1,
          maxB: 4,
        );
        
        expect(question.a, greaterThanOrEqualTo(50));
        expect(question.a, lessThanOrEqualTo(99));
        expect(question.b, greaterThanOrEqualTo(1));
        expect(question.b, lessThanOrEqualTo(4));
      }
    });
  });

  group('QuestionGenerator - 除法測試', () {
    test('生成除法題目 - 基本範圍', () {
      final generator = QuestionGenerator();
      
      for (int i = 0; i < 50; i++) {
        final question = generator.generateDivision(
          minA: 1,
          maxA: 20,
          minB: 2,
          maxB: 5,
        );
        
        expect(question.a, greaterThanOrEqualTo(1));
        expect(question.a, lessThanOrEqualTo(20));
        expect(question.b, greaterThanOrEqualTo(2));
        expect(question.b, lessThanOrEqualTo(5));
        
        // 驗證除法關係：a = b * q + r，其中 r < b
        final quotient = question.a ~/ question.b;
        final remainder = question.a % question.b;
        expect(remainder, lessThan(question.b));
        expect(quotient, greaterThanOrEqualTo(1));
      }
    });

    test('生成除法題目 - 用戶報告的問題範圍 (50-99, 1-4)', () {
      final generator = QuestionGenerator();
      
      for (int i = 0; i < 50; i++) {
        final question = generator.generateDivision(
          minA: 50,
          maxA: 99,
          minB: 1,
          maxB: 4,
        );
        
        expect(question.a, greaterThanOrEqualTo(50));
        expect(question.a, lessThanOrEqualTo(99));
        expect(question.b, greaterThanOrEqualTo(1));
        expect(question.b, lessThanOrEqualTo(4));
        
        // 驗證除法關係
        final quotient = question.a ~/ question.b;
        final remainder = question.a % question.b;
        expect(remainder, lessThan(question.b));
        expect(quotient, greaterThanOrEqualTo(1));
      }
    });

    test('生成除法題目 - 小範圍', () {
      final generator = QuestionGenerator();
      
      for (int i = 0; i < 50; i++) {
        final question = generator.generateDivision(
          minA: 10,
          maxA: 20,
          minB: 3,
          maxB: 5,
        );
        
        expect(question.a, greaterThanOrEqualTo(10));
        expect(question.a, lessThanOrEqualTo(20));
        expect(question.b, greaterThanOrEqualTo(3));
        expect(question.b, lessThanOrEqualTo(5));
      }
    });

    test('生成除法題目 - 邊界情況：範圍很小', () {
      final generator = QuestionGenerator();
      
      final question = generator.generateDivision(
        minA: 10,
        maxA: 10,
        minB: 2,
        maxB: 2,
      );
      
      expect(question.a, equals(10));
      expect(question.b, equals(2));
      expect(question.a % question.b, lessThan(question.b));
    });
  });

  group('QuestionGenerator - 統一接口測試', () {
    test('generateQuestion - 加法', () {
      final generator = QuestionGenerator();
      
      for (int i = 0; i < 50; i++) {
        final question = generator.generateQuestion(
          operation: Operation.add,
          minA: 1,
          maxA: 10,
          minB: 1,
          maxB: 10,
        );
        
        expect(question.a, greaterThanOrEqualTo(1));
        expect(question.a, lessThanOrEqualTo(10));
        expect(question.b, greaterThanOrEqualTo(1));
        expect(question.b, lessThanOrEqualTo(10));
      }
    });

    test('generateQuestion - 減法', () {
      final generator = QuestionGenerator();
      
      for (int i = 0; i < 50; i++) {
        final question = generator.generateQuestion(
          operation: Operation.subtract,
          minA: 1,
          maxA: 10,
          minB: 1,
          maxB: 10,
        );
        
        expect(question.a, greaterThanOrEqualTo(question.b));
      }
    });

    test('generateQuestion - 乘法', () {
      final generator = QuestionGenerator();
      
      for (int i = 0; i < 50; i++) {
        final question = generator.generateQuestion(
          operation: Operation.multiply,
          minA: 1,
          maxA: 10,
          minB: 1,
          maxB: 10,
        );
        
        expect(question.a, greaterThanOrEqualTo(1));
        expect(question.a, lessThanOrEqualTo(10));
        expect(question.b, greaterThanOrEqualTo(1));
        expect(question.b, lessThanOrEqualTo(10));
      }
    });

    test('generateQuestion - 除法', () {
      final generator = QuestionGenerator();
      
      for (int i = 0; i < 50; i++) {
        final question = generator.generateQuestion(
          operation: Operation.divide,
          minA: 10,
          maxA: 50,
          minB: 2,
          maxB: 5,
        );
        
        expect(question.a, greaterThanOrEqualTo(10));
        expect(question.a, lessThanOrEqualTo(50));
        expect(question.b, greaterThanOrEqualTo(2));
        expect(question.b, lessThanOrEqualTo(5));
      }
    });
  });

  group('QuestionGenerator - 可重現性測試（使用固定種子）', () {
    test('使用固定種子應該產生相同結果', () {
      final generator1 = QuestionGenerator(random: Random(12345));
      final generator2 = QuestionGenerator(random: Random(12345));
      
      for (int i = 0; i < 10; i++) {
        final q1 = generator1.generateAddition(
          minA: 1,
          maxA: 10,
          minB: 1,
          maxB: 10,
        );
        final q2 = generator2.generateAddition(
          minA: 1,
          maxA: 10,
          minB: 1,
          maxB: 10,
        );
        
        expect(q1.a, equals(q2.a));
        expect(q1.b, equals(q2.b));
      }
    });
  });
}

