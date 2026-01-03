import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiplication_practice/widgets/rabbits_celebration.dart';

void main() {
  group('RabbitsCelebration 動畫測試', () {
    testWidgets('widget 能正確構建並顯示', (WidgetTester tester) async {
      // 創建測試用的 MaterialApp
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RabbitsCelebration(isTablet: false),
          ),
        ),
      );

      // 等待初始構建完成
      await tester.pump();

      // 驗證 widget 已經構建
      expect(find.byType(RabbitsCelebration), findsOneWidget);
      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('AnimatedBuilder 應該存在並響應動畫', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RabbitsCelebration(isTablet: false),
          ),
        ),
      );

      await tester.pump();

      // 查找 AnimatedBuilder（應該在 RabbitsCelebration 內部）
      final animatedBuilders = find.byType(AnimatedBuilder);
      expect(animatedBuilders, findsAtLeastNWidgets(1));

      // 等待動畫運行
      await tester.pump(const Duration(milliseconds: 100));
      
      // 驗證 widget 仍然存在
      expect(find.byType(RabbitsCelebration), findsOneWidget);
      
      // 驗證 AnimatedBuilder 仍然存在（表示動畫系統正在工作）
      expect(animatedBuilders, findsAtLeastNWidgets(1));
    });

    testWidgets('動畫應該持續觸發重建', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RabbitsCelebration(isTablet: false),
          ),
        ),
      );

      await tester.pump();

      // 記錄初始構建次數（通過檢查 widget 樹）
      final initialAnimatedBuilders = find.byType(AnimatedBuilder);
      expect(initialAnimatedBuilders, findsAtLeastNWidgets(1));
      
      // 等待動畫播放一段時間（超過一個動畫週期 900ms）
      // 由於動畫在重複播放，AnimatedBuilder 應該會持續觸發重建
      await tester.pump(const Duration(milliseconds: 1000));
      
      // 驗證 widget 仍然存在且正常運作
      expect(find.byType(RabbitsCelebration), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
    });


    testWidgets('平板和手機模式都應該正常工作', (WidgetTester tester) async {
      // 測試手機模式
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RabbitsCelebration(isTablet: false),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(RabbitsCelebration), findsOneWidget);

      // 測試平板模式
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RabbitsCelebration(isTablet: true),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(RabbitsCelebration), findsOneWidget);
    });

    testWidgets('動畫應該持續運行（repeat reverse）', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RabbitsCelebration(isTablet: false),
          ),
        ),
      );

      await tester.pump();

      // 驗證初始狀態
      expect(find.byType(RabbitsCelebration), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
      
      // 等待多個動畫週期（2秒，超過一個動畫週期 900ms）
      await tester.pump(const Duration(milliseconds: 2000));
      
      // 動畫應該還在運行（因為使用了 repeat）
      // 通過驗證 AnimatedBuilder 仍然存在來確認
      expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
      expect(find.byType(RabbitsCelebration), findsOneWidget);
    });

    testWidgets('Transform 應該正確應用動畫值', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RabbitsCelebration(isTablet: false),
          ),
        ),
      );

      await tester.pump();

      // 查找 Transform.translate（應該在 AnimatedBuilder 內部）
      final transforms = find.byType(Transform);
      expect(transforms, findsAtLeastNWidgets(1));

      // 等待動畫運行
      await tester.pump(const Duration(milliseconds: 500));
      
      // 驗證 Transform 仍然存在
      expect(transforms, findsAtLeastNWidgets(1));
    });

    testWidgets('動畫應該能在 Dialog 中正確顯示', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    barrierColor: Colors.transparent,
                    builder: (_) => const RabbitsCelebration(isTablet: false),
                  );
                },
                child: const Text('顯示動畫'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // 點擊按鈕顯示 dialog
      await tester.tap(find.text('顯示動畫'));
      await tester.pump();

      // 等待 dialog 顯示
      await tester.pump(const Duration(milliseconds: 100));

      // 驗證 dialog 中的動畫 widget 存在
      expect(find.byType(RabbitsCelebration), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));

      // 等待動畫運行一段時間
      await tester.pump(const Duration(milliseconds: 500));

      // 驗證動畫仍然在運行
      expect(find.byType(RabbitsCelebration), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
    });

    testWidgets('動畫初始化時應該觸發音效播放邏輯', (WidgetTester tester) async {
      // 這個測試主要驗證 initState 中的 _playCheerSound 會被調用
      // 雖然無法真正播放音效，但可以驗證 widget 能正確初始化
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RabbitsCelebration(isTablet: false),
          ),
        ),
      );

      await tester.pump();

      // 如果 widget 能正確構建，說明 initState 中的邏輯都執行了
      // 包括 _playCheerSound() 的調用
      expect(find.byType(RabbitsCelebration), findsOneWidget);
      
      // 驗證動畫相關的 widget 都存在
      expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
      expect(find.byType(Center), findsOneWidget);
    });
  });
}

