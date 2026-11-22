import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenbo_web/in_game_page.dart';
import 'package:tenbo_web/score_request_page.dart';

void main() {
  const players = [
    GamePlayer(uid: 'winner', wind: '東', name: '和了者', score: 25000, isDealer: true),
    GamePlayer(uid: 'payer1', wind: '南', name: '南家', score: 25000),
    GamePlayer(uid: 'payer2', wind: '西', name: '西家', score: 25000),
    GamePlayer(uid: 'payer3', wind: '北', name: '北家', score: 25000),
  ];

  testWidgets('ロンを選択して点数を指定できる', (tester) async {
    Map<String, Object>? requested;
    await tester.pumpWidget(MaterialApp(home: ScoreRequestPage(
      players: players,
      winnerUid: 'winner',
      onRequest: ({required isTsumo, required ronPoints, required dealerPayment,
        required nonDealerPayment, required yakumanMultiplier}) async {
        requested = {'isTsumo': isTsumo, 'ronPoints': ronPoints,
          'dealerPayment': dealerPayment, 'nonDealerPayment': nonDealerPayment,
          'yakumanMultiplier': yakumanMultiplier};
      },
    )));
    expect(find.text('和了者：和了者'), findsOneWidget);
    expect(find.text('東 和了者  25,000点'), findsOneWidget);
    expect(find.text('20符'), findsNothing);
    expect(find.text('30符'), findsNothing);
    expect(find.text('50符'), findsNothing);
    expect(find.byType(GridView), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('3,900点'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    final ronChoice = find.ancestor(
      of: find.text('3,900点'),
      matching: find.byType(ChoiceChip),
    );
    await tester.tap(ronChoice);
    await tester.pump();
    expect(tester.widget<ChoiceChip>(ronChoice).selected, isTrue);
    final submitButton = find.ancestor(
      of: find.text('支払いを依頼する'),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(submitButton).onPressed, isNotNull);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(requested?['isTsumo'], false);
    expect(requested?['ronPoints'], 3900);
    expect(requested?['yakumanMultiplier'], 2);
  });

  testWidgets('ツモでは親子の支払い額ペアを選択できる', (tester) async {
    Map<String, Object>? requested;
    await tester.pumpWidget(MaterialApp(home: ScoreRequestPage(
      players: players,
      winnerUid: 'winner',
      onRequest: ({required isTsumo, required ronPoints, required dealerPayment,
        required nonDealerPayment, required yakumanMultiplier}) async {
        requested = {'isTsumo': isTsumo, 'ronPoints': ronPoints,
          'dealerPayment': dealerPayment, 'nonDealerPayment': nonDealerPayment,
          'yakumanMultiplier': yakumanMultiplier};
      },
    )));
    await tester.tap(find.text('ツモ'));
    await tester.pumpAndSettle();
    expect(find.text('放銃者からの支払い点数'), findsNothing);
    expect(find.byType(GridView), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('300 / 500'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    final tsumoChoice = find.ancestor(
      of: find.text('300 / 500'),
      matching: find.byType(ChoiceChip),
    );
    await tester.tap(tsumoChoice);
    await tester.pump();
    expect(tester.widget<ChoiceChip>(tsumoChoice).selected, isTrue);
    final submitButton = find.ancestor(
      of: find.text('支払いを依頼する'),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(submitButton).onPressed, isNotNull);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
    expect(requested?['isTsumo'], true);
    expect(requested?['dealerPayment'], 500);
    expect(requested?['nonDealerPayment'], 300);
  });

  testWidgets('役満倍率は初期値2倍で変更できる', (tester) async {
    await tester.pumpWidget(MaterialApp(home: ScoreRequestPage(
      players: players,
      winnerUid: 'winner',
      onRequest: ({required isTsumo, required ronPoints, required dealerPayment,
        required nonDealerPayment, required yakumanMultiplier}) async {},
    )));
    await tester.scrollUntilVisible(
      find.text('役満'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('2倍役満'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3倍役満').last);
    await tester.pumpAndSettle();
    expect(find.text('3倍役満'), findsOneWidget);
  });
}
