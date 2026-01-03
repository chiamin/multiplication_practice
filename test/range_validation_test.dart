import 'package:flutter_test/flutter_test.dart';
import 'package:multiplication_practice/utils/question_generator.dart';
import 'package:multiplication_practice/models/operation.dart';

void main() {
  group('範圍驗證測試 - 所有運算都遵守範圍', () {
    test('加法 - 嚴格範圍驗證', () {
      final generator = QuestionGenerator();
      
      const iterations = 200;
      for (int i = 0; i < iterations; i++) {
        final question = generator.generateAddition(
          minA: 50,
          maxA: 99,
          minB: 1,
          maxB: 4,
        );
        
        expect(
          question.a,
          greaterThanOrEqualTo(50),
          reason: '第 $i 次迭代：a 應該 >= 50，實際值：${question.a}',
        );
        expect(
          question.a,
          lessThanOrEqualTo(99),
          reason: '第 $i 次迭代：a 應該 <= 99，實際值：${question.a}',
        );
        expect(
          question.b,
          greaterThanOrEqualTo(1),
          reason: '第 $i 次迭代：b 應該 >= 1，實際值：${question.b}',
        );
        expect(
          question.b,
          lessThanOrEqualTo(4),
          reason: '第 $i 次迭代：b 應該 <= 4，實際值：${question.b}',
        );
      }
    });

    test('減法 - 嚴格範圍驗證且 a >= b', () {
      final generator = QuestionGenerator();
      
      const iterations = 200;
      for (int i = 0; i < iterations; i++) {
        final question = generator.generateSubtraction(
          minA: 50,
          maxA: 99,
          minB: 1,
          maxB: 4,
        );
        
        expect(
          question.a,
          greaterThanOrEqualTo(50),
          reason: '第 $i 次迭代：a 應該 >= 50',
        );
        expect(
          question.a,
          lessThanOrEqualTo(99),
          reason: '第 $i 次迭代：a 應該 <= 99',
        );
        expect(
          question.b,
          greaterThanOrEqualTo(1),
          reason: '第 $i 次迭代：b 應該 >= 1',
        );
        expect(
          question.b,
          lessThanOrEqualTo(4),
          reason: '第 $i 次迭代：b 應該 <= 4',
        );
        expect(
          question.a,
          greaterThanOrEqualTo(question.b),
          reason: '第 $i 次迭代：a 應該 >= b',
        );
      }
    });

    test('乘法 - 嚴格範圍驗證', () {
      final generator = QuestionGenerator();
      
      const iterations = 200;
      for (int i = 0; i < iterations; i++) {
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

    test('除法 - 嚴格範圍驗證（用戶報告的問題）', () {
      final generator = QuestionGenerator();
      
      const iterations = 200;
      int successCount = 0;
      
      for (int i = 0; i < iterations; i++) {
        final question = generator.generateDivision(
          minA: 50,
          maxA: 99,
          minB: 1,
          maxB: 4,
        );
        
        final aInRange = question.a >= 50 && question.a <= 99;
        final bInRange = question.b >= 1 && question.b <= 4;
        
        if (aInRange && bInRange) {
          successCount++;
        }
        
        expect(
          aInRange,
          isTrue,
          reason: '第 $i 次迭代：a = ${question.a} 不在範圍 [50, 99] 內',
        );
        expect(
          bInRange,
          isTrue,
          reason: '第 $i 次迭代：b = ${question.b} 不在範圍 [1, 4] 內',
        );
        
        // 驗證除法關係
        final quotient = question.a ~/ question.b;
        final remainder = question.a % question.b;
        expect(remainder, lessThan(question.b));
        expect(quotient, greaterThanOrEqualTo(1));
      }
      
      // 至少應該有大部分成功（考慮到隨機性，允許少量失敗）
      expect(successCount, greaterThan(iterations * 0.9));
    });
  });

  group('邊界情況測試', () {
    test('單一值範圍', () {
      final generator = QuestionGenerator();
      
      final addQuestion = generator.generateAddition(
        minA: 5,
        maxA: 5,
        minB: 3,
        maxB: 3,
      );
      expect(addQuestion.a, equals(5));
      expect(addQuestion.b, equals(3));
      
      final subQuestion = generator.generateSubtraction(
        minA: 10,
        maxA: 10,
        minB: 5,
        maxB: 5,
      );
      expect(subQuestion.a, equals(10));
      expect(subQuestion.b, equals(5));
    });

    test('範圍反轉自動修正', () {
      final generator = QuestionGenerator();
      
      for (int i = 0; i < 50; i++) {
        final question = generator.generateAddition(
          minA: 10,
          maxA: 1,
          minB: 5,
          maxB: 2,
        );
        
        expect(question.a, greaterThanOrEqualTo(1));
        expect(question.a, lessThanOrEqualTo(10));
        expect(question.b, greaterThanOrEqualTo(2));
        expect(question.b, lessThanOrEqualTo(5));
      }
    });

    test('極小範圍', () {
      final generator = QuestionGenerator();
      
      for (int i = 0; i < 20; i++) {
        final question = generator.generateAddition(
          minA: 1,
          maxA: 2,
          minB: 1,
          maxB: 2,
        );
        
        expect(question.a, greaterThanOrEqualTo(1));
        expect(question.a, lessThanOrEqualTo(2));
        expect(question.b, greaterThanOrEqualTo(1));
        expect(question.b, lessThanOrEqualTo(2));
      }
    });

    test('極大範圍', () {
      final generator = QuestionGenerator();
      
      for (int i = 0; i < 20; i++) {
        final question = generator.generateAddition(
          minA: 1000,
          maxA: 9999,
          minB: 100,
          maxB: 999,
        );
        
        expect(question.a, greaterThanOrEqualTo(1000));
        expect(question.a, lessThanOrEqualTo(9999));
        expect(question.b, greaterThanOrEqualTo(100));
        expect(question.b, lessThanOrEqualTo(999));
      }
    });
  });

  group('特殊情況測試', () {
    test('減法 - 範圍A完全小於範圍B', () {
      final generator = QuestionGenerator();
      
      // 當範圍A的最大值都小於範圍B的最小值時，無法生成有效的減法題目
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
      expect(question.b, greaterThanOrEqualTo(1)); // 至少是正數
    });

    test('除法 - 無法生成有效題目的情況', () {
      final generator = QuestionGenerator();
      
      // 當範圍A太小而範圍B太大時
      final question = generator.generateDivision(
        minA: 1,
        maxA: 5,
        minB: 10,
        maxB: 20,
      );
      
      // 應該至少返回一個有效的組合（可能使用 fallback）
      expect(question.a, greaterThanOrEqualTo(1));
      expect(question.a, lessThanOrEqualTo(5));
      expect(question.b, greaterThanOrEqualTo(10));
      expect(question.b, lessThanOrEqualTo(20));
    });
  });

  group('一致性測試', () {
    test('多次生成應該都在範圍內', () {
      final generator = QuestionGenerator();
      const testRanges = [
        (minA: 1, maxA: 10, minB: 1, maxB: 10),
        (minA: 50, maxA: 99, minB: 1, maxB: 4),
        (minA: 100, maxA: 200, minB: 10, maxB: 20),
        (minA: 1, maxA: 100, minB: 1, maxB: 100),
      ];
      
      for (final range in testRanges) {
        for (final operation in Operation.values) {
          for (int i = 0; i < 50; i++) {
            final question = generator.generateQuestion(
              operation: operation,
              minA: range.minA,
              maxA: range.maxA,
              minB: range.minB,
              maxB: range.maxB,
            );
            
            expect(
              question.a,
              greaterThanOrEqualTo(range.minA),
              reason: '${operation.name}: a 應該 >= ${range.minA}',
            );
            expect(
              question.a,
              lessThanOrEqualTo(range.maxA),
              reason: '${operation.name}: a 應該 <= ${range.maxA}',
            );
            expect(
              question.b,
              greaterThanOrEqualTo(range.minB),
              reason: '${operation.name}: b 應該 >= ${range.minB}',
            );
            expect(
              question.b,
              lessThanOrEqualTo(range.maxB),
              reason: '${operation.name}: b 應該 <= ${range.maxB}',
            );
            
            // 減法特殊檢查
            if (operation == Operation.subtract) {
              expect(
                question.a,
                greaterThanOrEqualTo(question.b),
                reason: '減法：a 應該 >= b',
              );
            }
          }
        }
      }
    });
  });
}

