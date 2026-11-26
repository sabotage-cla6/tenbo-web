import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenbo_web/in_game_page.dart';
import 'package:tenbo_web/score_request_page.dart';

void main() {
  const players = [
    GamePlayer(uid: 'winner', wind: '東', name: '和了者', score: 25000, isDealer: true),
    GamePlayer(uid: 'south', wind: '南', name: '南家', score: 25000),
    GamePlayer(uid: 'west', wind: '西', name: '西家', score: 25000),
    GamePlayer(uid: 'north', wind: '北', name: '北家', score: 25000),
  ];

  testWidgets('点数入力画面に和了方式と点数選択肢を表示する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ScoreRequestPage(
          players: players,
          winnerUid: 'winner',
          onRequest: _noopRequest,
        ),
      ),
    );

    expect(find.text('和了（上がり）点数入力'), findsOneWidget);
    expect(find.text('ロン'), findsOneWidget);
    expect(find.text('ツモ'), findsOneWidget);
    expect(find.text('点数・役の選択'), findsOneWidget);
    expect(find.text('点数請求'), findsOneWidget);
  });

  testWidgets('ツモを選択するとツモの支払額候補を表示する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ScoreRequestPage(
          players: players,
          winnerUid: 'winner',
          onRequest: _noopRequest,
        ),
      ),
    );

    await tester.tap(find.text('ツモ'));
    await tester.pump();

    expect(find.textContaining('all'), findsWidgets);
  });
}

Future<void> _noopRequest({
  required bool isDealer,
  required bool isTsumo,
  required int ronPoints,
  required int dealerPayment,
  required int nonDealerPayment,
  required int yakumanMultiplier,
  required int honba,
}) async {}
