import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenbo_web/in_game_page.dart';

void main() {
  const players = [
    GamePlayer(wind: '東', name: '上家', score: 31500, isDealer: true, isRiichi: true, isYakitori: true),
    GamePlayer(wind: '南', name: '自分', score: 23000, isYakitori: true),
    GamePlayer(wind: '西', name: '下家', score: 24000, isYakitori: true),
    GamePlayer(wind: '北', name: '対面', score: 21500),
  ];

  Widget buildPage({List<GamePlayer> gamePlayers = players}) => MaterialApp(
        home: InGamePage(
          tableName: '金曜夜セット麻雀',
          players: gamePlayers,
          round: '東1局',
          honba: 0,
          kyotaku: 1000,
        ),
      );

  group('InGamePage', () {
    testWidgets('卓名・局情報・4人の点数と状態を表示する', (tester) async {
      await tester.pumpWidget(buildPage());

      expect(find.text('金曜夜セット麻雀'), findsOneWidget);
      expect(find.text('東1局'), findsNWidgets(2));
      expect(find.text('0 本場'), findsOneWidget);
      expect(find.text('1,000点'), findsOneWidget);
      expect(find.text('上家'), findsOneWidget);
      expect(find.text('自分'), findsOneWidget);
      expect(find.text('下家'), findsOneWidget);
      expect(find.text('対面'), findsOneWidget);
      expect(find.text('31,500'), findsOneWidget);
      expect(find.text('23,000'), findsOneWidget);
      expect(find.text('⚡ 立直'), findsOneWidget);
      expect(find.text('🍢 焼き鳥'), findsNWidgets(3));
      expect(find.text('リーチ'), findsOneWidget);
      expect(find.text('和了'), findsOneWidget);
      expect(find.text('点棒移動'), findsOneWidget);
      expect(find.text('流局'), findsOneWidget);
      expect(find.text('次局へ'), findsOneWidget);
      expect(find.text('精算'), findsOneWidget);
    });

    testWidgets('三人麻雀では北家を表示せず三人麻雀と表示する', (tester) async {
      const sanmaPlayers = [
        GamePlayer(wind: '東', name: '東家', score: 35000, isDealer: true),
        GamePlayer(wind: '南', name: '南家', score: 32000),
        GamePlayer(wind: '西', name: '西家', score: 33000),
      ];
      await tester.pumpWidget(buildPage(gamePlayers: sanmaPlayers));

      expect(find.text('三人麻雀'), findsOneWidget);
      expect(find.text('東家'), findsOneWidget);
      expect(find.text('南家'), findsOneWidget);
      expect(find.text('西家'), findsOneWidget);
    });

    testWidgets('操作ボタンは未実装であることを案内する', (tester) async {
      await tester.pumpWidget(buildPage());

      await tester.tap(find.text('和了'));
      await tester.pump();

      expect(find.text('和了機能は今後実装します。'), findsOneWidget);
    });
  });
}
