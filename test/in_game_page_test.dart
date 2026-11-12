import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tenbo_web/in_game_page.dart';
import 'package:tenbo_web/table_repository.dart';
import 'helpers/mock_table_repository.dart';

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
      expect(find.text('東1局'), findsOneWidget);
      expect(find.text('東1局  •  配点 25,000点'), findsOneWidget);
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


    testWidgets('確認ダイアログなしでリーチし、もう一度押すと解除を依頼する', (tester) async {
      final controller = StreamController<GameState>();
      var riichiCallCount = 0;
      const statePlayers = [
        GamePlayer(uid: 'east-uid', wind: '東', name: '東家', score: 25000, isDealer: true),
        GamePlayer(uid: 'south-uid', wind: '南', name: '南家', score: 25000),
        GamePlayer(uid: 'west-uid', wind: '西', name: '西家', score: 25000),
        GamePlayer(uid: 'north-uid', wind: '北', name: '北家', score: 25000),
      ];
      await tester.pumpWidget(MaterialApp(home: InGamePage(
        tableName: 'テスト卓', players: statePlayers, tableId: 'table-123',
        currentUserUid: 'south-uid', gameStateStream: controller.stream,
        onRiichi: () async { riichiCallCount++; },
      )));
      controller.add(const GameState(
        round: GameRound(wind: 'east', number: 1, honba: 0, seq: 1),
        kyotakuSticks: 0,
        players: {
          'east-uid': GamePlayerState(score: 25000, isRiichi: false),
          'south-uid': GamePlayerState(score: 25000, isRiichi: false),
          'west-uid': GamePlayerState(score: 25000, isRiichi: false),
          'north-uid': GamePlayerState(score: 25000, isRiichi: false),
        },
      ));
      await tester.pump();
      final riichiButton = find.text('リーチ');
      await tester.ensureVisible(riichiButton);
      await tester.pumpAndSettle();
      await tester.tap(riichiButton);
      await tester.pumpAndSettle();
      expect(find.text('リーチしますか？'), findsNothing);
      expect(riichiCallCount, 1);
      controller.add(const GameState(
        round: GameRound(wind: 'east', number: 1, honba: 0, seq: 1),
        kyotakuSticks: 1,
        players: {
          'east-uid': GamePlayerState(score: 25000, isRiichi: false),
          'south-uid': GamePlayerState(score: 24000, isRiichi: true),
          'west-uid': GamePlayerState(score: 25000, isRiichi: false),
          'north-uid': GamePlayerState(score: 25000, isRiichi: false),
        },
      ));
      await tester.pump();
      expect(find.text('24,000'), findsOneWidget);
      expect(find.text('1,000点'), findsOneWidget);
      expect(find.text('⚡ 立直'), findsOneWidget);
      await tester.tap(riichiButton);
      await tester.pump();
      expect(riichiCallCount, 2);
      controller.add(const GameState(
        round: GameRound(wind: 'east', number: 1, honba: 0, seq: 1),
        kyotakuSticks: 0,
        players: {
          'east-uid': GamePlayerState(score: 25000, isRiichi: false),
          'south-uid': GamePlayerState(score: 25000, isRiichi: false),
          'west-uid': GamePlayerState(score: 25000, isRiichi: false),
          'north-uid': GamePlayerState(score: 25000, isRiichi: false),
        },
      ));
      await tester.pump();
      expect(find.text('25,000'), findsOneWidget);
      expect(find.text('⚡ 立直'), findsNothing);
      await controller.close();
    });

    testWidgets('Repositoryから取得した対局状態を表示する', (tester) async {
      final repository = MockTableRepository();
      when(repository.watchGameState('table-123')).thenAnswer((_) => Stream.value(
        const GameState(
          round: GameRound(wind: 'south', number: 2, honba: 1, seq: 2),
          kyotakuSticks: 2,
          players: {
            'south-uid': GamePlayerState(score: 24000, isRiichi: true),
          },
        ),
      ));

      await tester.pumpWidget(MaterialApp(
        home: InGamePage(
          tableName: 'テスト卓',
          players: const [
            GamePlayer(uid: 'south-uid', wind: '南', name: '自分', score: 25000),
          ],
          tableId: 'table-123',
          currentUserUid: 'south-uid',
          repository: repository,
        ),
      ));
      await tester.pump();

      expect(find.text('南2局'), findsOneWidget);
      expect(find.text('24,000'), findsOneWidget);
      expect(find.text('2,000点'), findsOneWidget);
      expect(find.text('⚡ 立直'), findsOneWidget);
      verify(repository.watchGameState('table-123')).called(1);
    });

    testWidgets('リーチ操作を注入されたRepositoryへ依頼する', (tester) async {
      final repository = MockTableRepository();
      when(repository.watchGameState('table-123')).thenAnswer((_) => Stream.value(
        const GameState(
          round: GameRound(wind: 'east', number: 1, honba: 0, seq: 1),
          kyotakuSticks: 0,
          players: {
            'south-uid': GamePlayerState(score: 25000, isRiichi: false),
          },
        ),
      ));
      when(repository.declareRiichi('table-123')).thenAnswer((_) async {});

      await tester.pumpWidget(MaterialApp(
        home: InGamePage(
          tableName: 'テスト卓',
          players: const [
            GamePlayer(uid: 'south-uid', wind: '南', name: '自分', score: 25000),
          ],
          tableId: 'table-123',
          currentUserUid: 'south-uid',
          repository: repository,
        ),
      ));
      await tester.pump();

      await tester.ensureVisible(find.text('リーチ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('リーチ'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      verify(repository.toggleRiichi('table-123')).called(1);
    });

    testWidgets('操作ボタンは未実装であることを案内する', (tester) async {
      await tester.pumpWidget(buildPage());

      final winButton = find.text('和了');
      await tester.ensureVisible(winButton);
      await tester.pumpAndSettle();
      await tester.tap(winButton);
      await tester.pump();

      expect(find.text('和了機能は今後実装します。'), findsOneWidget);
    });
  });
}
