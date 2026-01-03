import 'package:flutter_test/flutter_test.dart';
import 'package:multiplication_practice/utils/question_generator.dart';
import 'package:multiplication_practice/models/operation.dart';

void main() {
  group('AnswerChecker - 基本運算測試', () {
    test('calculateCorrectAnswer - 加法', () {
      final checker = AnswerChecker();
      
      expect(
        checker.calculateCorrectAnswer(
          operation: Operation.add,
          a: 5,
          b: 3,
        ),
        equals(8),
      );
      
      expect(
        checker.calculateCorrectAnswer(
          operation: Operation.add,
          a: 0,
          b: 0,
        ),
        equals(0),
      );
      
      expect(
        checker.calculateCorrectAnswer(
          operation: Operation.add,
          a: 100,
          b: 50,
        ),
        equals(150),
      );
    });

    test('calculateCorrectAnswer - 減法', () {
      final checker = AnswerChecker();
      
      expect(
        checker.calculateCorrectAnswer(
          operation: Operation.subtract,
          a: 10,
          b: 3,
        ),
        equals(7),
      );
      
      expect(
        checker.calculateCorrectAnswer(
          operation: Operation.subtract,
          a: 5,
          b: 5,
        ),
        equals(0),
      );
      
      expect(
        checker.calculateCorrectAnswer(
          operation: Operation.subtract,
          a: 100,
          b: 50,
        ),
        equals(50),
      );
    });

    test('calculateCorrectAnswer - 乘法', () {
      final checker = AnswerChecker();
      
      expect(
        checker.calculateCorrectAnswer(
          operation: Operation.multiply,
          a: 5,
          b: 3,
        ),
        equals(15),
      );
      
      expect(
        checker.calculateCorrectAnswer(
          operation: Operation.multiply,
          a: 0,
          b: 10,
        ),
        equals(0),
      );
      
      expect(
        checker.calculateCorrectAnswer(
          operation: Operation.multiply,
          a: 10,
          b: 0,
        ),
        equals(0),
      );
      
      expect(
        checker.calculateCorrectAnswer(
          operation: Operation.multiply,
          a: 7,
          b: 8,
        ),
        equals(56),
      );
    });

    test('calculateCorrectAnswer - 除法應該拋出錯誤', () {
      final checker = AnswerChecker();
      
      expect(
        () => checker.calculateCorrectAnswer(
          operation: Operation.divide,
          a: 10,
          b: 2,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('AnswerChecker - 答案檢查測試', () {
    test('checkAnswer - 加法正確答案', () {
      final checker = AnswerChecker();
      
      expect(
        checker.checkAnswer(
          operation: Operation.add,
          a: 5,
          b: 3,
          userAnswer: 8,
        ),
        isTrue,
      );
    });

    test('checkAnswer - 加法錯誤答案', () {
      final checker = AnswerChecker();
      
      expect(
        checker.checkAnswer(
          operation: Operation.add,
          a: 5,
          b: 3,
          userAnswer: 7,
        ),
        isFalse,
      );
    });

    test('checkAnswer - 減法正確答案', () {
      final checker = AnswerChecker();
      
      expect(
        checker.checkAnswer(
          operation: Operation.subtract,
          a: 10,
          b: 3,
          userAnswer: 7,
        ),
        isTrue,
      );
    });

    test('checkAnswer - 減法錯誤答案', () {
      final checker = AnswerChecker();
      
      expect(
        checker.checkAnswer(
          operation: Operation.subtract,
          a: 10,
          b: 3,
          userAnswer: 8,
        ),
        isFalse,
      );
    });

    test('checkAnswer - 乘法正確答案', () {
      final checker = AnswerChecker();
      
      expect(
        checker.checkAnswer(
          operation: Operation.multiply,
          a: 5,
          b: 3,
          userAnswer: 15,
        ),
        isTrue,
      );
    });

    test('checkAnswer - 乘法錯誤答案', () {
      final checker = AnswerChecker();
      
      expect(
        checker.checkAnswer(
          operation: Operation.multiply,
          a: 5,
          b: 3,
          userAnswer: 14,
        ),
        isFalse,
      );
    });
  });

  group('AnswerChecker - 除法答案檢查測試', () {
    test('checkDivisionAnswer - 正確答案（無餘數）', () {
      final checker = AnswerChecker();
      
      final result = checker.checkDivisionAnswer(
        a: 10,
        b: 2,
        quotient: 5,
        remainder: 0,
      );
      
      expect(result.isCorrect, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('checkDivisionAnswer - 正確答案（有餘數）', () {
      final checker = AnswerChecker();
      
      final result = checker.checkDivisionAnswer(
        a: 10,
        b: 3,
        quotient: 3,
        remainder: 1,
      );
      
      expect(result.isCorrect, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('checkDivisionAnswer - 錯誤商', () {
      final checker = AnswerChecker();
      
      final result = checker.checkDivisionAnswer(
        a: 10,
        b: 3,
        quotient: 4,
        remainder: 1,
      );
      
      expect(result.isCorrect, isFalse);
      expect(result.errorMessage, isNull);
    });

    test('checkDivisionAnswer - 錯誤餘數', () {
      final checker = AnswerChecker();
      
      final result = checker.checkDivisionAnswer(
        a: 10,
        b: 3,
        quotient: 3,
        remainder: 2,
      );
      
      expect(result.isCorrect, isFalse);
      expect(result.errorMessage, isNull);
    });

    test('checkDivisionAnswer - 餘數大於等於除數（應該返回錯誤訊息）', () {
      final checker = AnswerChecker();
      
      final result = checker.checkDivisionAnswer(
        a: 10,
        b: 3,
        quotient: 3,
        remainder: 3,
      );
      
      expect(result.isCorrect, isFalse);
      expect(result.errorMessage, equals('餘數應該小於除數喔'));
    });

    test('checkDivisionAnswer - 餘數大於除數', () {
      final checker = AnswerChecker();
      
      final result = checker.checkDivisionAnswer(
        a: 10,
        b: 3,
        quotient: 3,
        remainder: 5,
      );
      
      expect(result.isCorrect, isFalse);
      expect(result.errorMessage, equals('餘數應該小於除數喔'));
    });

    test('checkDivisionAnswer - 各種除法情況', () {
      final checker = AnswerChecker();
      
      // 測試多種情況
      final testCases = [
        (a: 50, b: 4, q: 12, r: 2, expected: true),
        (a: 99, b: 4, q: 24, r: 3, expected: true),
        (a: 51, b: 1, q: 51, r: 0, expected: true),
        (a: 52, b: 2, q: 26, r: 0, expected: true),
        (a: 53, b: 3, q: 17, r: 2, expected: true),
      ];
      
      for (final testCase in testCases) {
        final result = checker.checkDivisionAnswer(
          a: testCase.a,
          b: testCase.b,
          quotient: testCase.q,
          remainder: testCase.r,
        );
        
        expect(
          result.isCorrect,
          equals(testCase.expected),
          reason: '${testCase.a} ÷ ${testCase.b} = ${testCase.q} ... ${testCase.r}',
        );
      }
    });
  });

  group('AnswerChecker - 邊界情況測試', () {
    test('大數字運算', () {
      final checker = AnswerChecker();
      
      expect(
        checker.checkAnswer(
          operation: Operation.add,
          a: 999999,
          b: 1,
          userAnswer: 1000000,
        ),
        isTrue,
      );
      
      expect(
        checker.checkAnswer(
          operation: Operation.multiply,
          a: 1000,
          b: 1000,
          userAnswer: 1000000,
        ),
        isTrue,
      );
    });

    test('零值處理', () {
      final checker = AnswerChecker();
      
      expect(
        checker.checkAnswer(
          operation: Operation.add,
          a: 0,
          b: 0,
          userAnswer: 0,
        ),
        isTrue,
      );
      
      expect(
        checker.checkAnswer(
          operation: Operation.multiply,
          a: 0,
          b: 100,
          userAnswer: 0,
        ),
        isTrue,
      );
    });

    test('負數結果（減法）', () {
      final checker = AnswerChecker();
      
      // 注意：在實際應用中，減法應該確保 a >= b，但這裡測試計算邏輯
      expect(
        checker.calculateCorrectAnswer(
          operation: Operation.subtract,
          a: 3,
          b: 5,
        ),
        equals(-2),
      );
    });
  });

  group('AnswerChecker - 整合測試', () {
    test('完整流程：生成題目 -> 計算答案 -> 檢查答案', () {
      final generator = QuestionGenerator();
      final checker = AnswerChecker();
      
      // 測試加法
      for (int i = 0; i < 10; i++) {
        final question = generator.generateQuestion(
          operation: Operation.add,
          minA: 1,
          maxA: 10,
          minB: 1,
          maxB: 10,
        );
        
        final correctAnswer = checker.calculateCorrectAnswer(
          operation: Operation.add,
          a: question.a,
          b: question.b,
        );
        
        expect(
          checker.checkAnswer(
            operation: Operation.add,
            a: question.a,
            b: question.b,
            userAnswer: correctAnswer,
          ),
          isTrue,
        );
      }
      
      // 測試乘法
      for (int i = 0; i < 10; i++) {
        final question = generator.generateQuestion(
          operation: Operation.multiply,
          minA: 1,
          maxA: 10,
          minB: 1,
          maxB: 10,
        );
        
        final correctAnswer = checker.calculateCorrectAnswer(
          operation: Operation.multiply,
          a: question.a,
          b: question.b,
        );
        
        expect(
          checker.checkAnswer(
            operation: Operation.multiply,
            a: question.a,
            b: question.b,
            userAnswer: correctAnswer,
          ),
          isTrue,
        );
      }
      
      // 測試除法
      for (int i = 0; i < 10; i++) {
        final question = generator.generateQuestion(
          operation: Operation.divide,
          minA: 10,
          maxA: 50,
          minB: 2,
          maxB: 5,
        );
        
        final correctQuotient = question.a ~/ question.b;
        final correctRemainder = question.a % question.b;
        
        final result = checker.checkDivisionAnswer(
          a: question.a,
          b: question.b,
          quotient: correctQuotient,
          remainder: correctRemainder,
        );
        
        expect(result.isCorrect, isTrue);
      }
    });
  });
}

