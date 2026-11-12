import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenbo_web/game_page.dart';

void main() {
  Widget buildGame({int playerCount = 4}) {
    return MaterialApp(
      home: GamePage(
        tableName: '金曜夜セット麻雀',
        playerCount: playerCount,
        startingPoints: 25000,
        players: const {
          '東': 'プレイヤーA',
          '南': 'プレイヤーB',
          '西': 'プレイヤーC',
          '北': 'プレイヤーD',
        },
      ),
    );
  }

  group('GamePage', () {
    testWidgets('対局情報・4人分の点数・操作メニューを表示する', (tester) async {
      await tester.view.setPhysicalSize(const Size(900, 1200));
      await tester.view.setDevicePixelRatio(1);
      await tester.pumpWidget(buildGame());

      expect(find.text('金曜夜セット麻雀'), findsOneWidget);
      expect(find.text('対局中'), findsOneWidget);
      expect(find.text('東 1 局'), findsOneWidget);
      expect(find.text('0 本場'), findsOneWidget);
      expect(find.text('プレイヤーA'), findsOneWidget);
      expect(find.text('プレイヤーB'), findsOneWidget);
      expect(find.text('プレイヤーC'), findsOneWidget);
      expect(find.text('プレイヤーD'), findsOneWidget);
      expect(find.text('リーチ'), findsOneWidget);
      expect(find.text('和了'), findsOneWidget);
      expect(find.text('点棒移動'), findsOneWidget);
      expect(find.text('流局'), findsOneWidget);
      expect(find.text('次局へ'), findsOneWidget);
      expect(find.text('精算'), findsOneWidget);

      await tester.view.resetPhysicalSize();
    });

    testWidgets('三人麻雀では北家を表示しない', (tester) async {
      await tester.view.setPhysicalSize(const Size(900, 1200));
      await tester.view.setDevicePixelRatio(1);
      await tester.pumpWidget(buildGame(playerCount: 3));

      expect(find.text('プレイヤーA'), findsOneWidget);
      expect(find.text('プレイヤーB'), findsOneWidget);
      expect(find.text('プレイヤーC'), findsOneWidget);
      expect(find.text('プレイヤーD'), findsNothing);
      expect(find.text('3人麻雀'), findsOneWidget);

      await tester.view.resetPhysicalSize();
    });

    testWidgets('操作ボタンは未実装であることを案内する', (tester) async {
      await tester.view.setPhysicalSize(const Size(900, 1200));
      await tester.view.setDevicePixelRatio(1);
      await tester.pumpWidget(buildGame());

      await tester.tap(find.text('リーチ'));
      await tester.pump();

      expect(find.text('リーチ機能は準備中です。'), findsOneWidget);
      await tester.view.resetPhysicalSize();
    });
  });
}
