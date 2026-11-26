// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:tenbo_web/in_game_page.dart';
// import 'package:tenbo_web/score_request_page.dart';

// void main() {
//   const players = [
//     GamePlayer(uid: 'winner', wind: '東', name: '和了者', score: 25000, isDealer: true),
//     GamePlayer(uid: 'payer1', wind: '南', name: '南家', score: 24000),
//     GamePlayer(uid: 'payer2', wind: '西', name: '西家', score: 26000),
//     GamePlayer(uid: 'payer3', wind: '北', name: '北家', score: 25000),
//   ];

//   testWidgets('対局画面風の点数表示と符・翻別のロン点数を選択できる', (tester) async {
//     Map<String, Object>? requested;
//     await tester.pumpWidget(MaterialApp(home: ScoreRequestPage(
//       players: players,
//       winnerUid: 'winner',
//       onRequest: ({required isTsumo, required ronPoints, required dealerPayment,
//         required nonDealerPayment, required yakumanMultiplier, required honba}) async {
//         requested = {
//           'isTsumo': isTsumo,
//           'ronPoints': ronPoints,
//           'dealerPayment': dealerPayment,
//           'nonDealerPayment': nonDealerPayment,
//           'yakumanMultiplier': yakumanMultiplier,
//           'honba': honba,
//         };
//       },
//     )));

//     expect(find.text('和了者の立場'), findsOneWidget);
//     expect(find.text('親（東）'), findsOneWidget);
//     expect(find.text('子'), findsOneWidget);
//     expect(find.text('本場'), findsOneWidget);
//     expect(find.text('20符'), findsOneWidget);
//     expect(find.text('30符'), findsOneWidget);
//     expect(find.text('50符'), findsOneWidget);
//     expect(find.text('70符'), findsOneWidget);
//     expect(find.textContaining('90符'), findsNWidgets(2));
//     expect(find.textContaining('110符'), findsNWidgets(2));
//     expect(find.text('1翻'), findsOneWidget);
//     expect(find.text('2翻'), findsOneWidget);
//     expect(find.text('4倍満'), findsOneWidget);
//     expect(find.text('役満'), findsOneWidget);
//     expect(find.text('2倍役満'), findsOneWidget);

//     // 20符1翻のロンは選択肢を設けない。
//     expect(find.text('1,300点'), findsOneWidget);
//     final ronChoice = find.ancestor(
//       of: find.text('2,000点'),
//       matching: find.byType(InkWell),
//     ).first;
//     await tester.ensureVisible(ronChoice);
//     await tester.tap(ronChoice);
//     await tester.pump();

//     final submit = find.text('点数請求');
//     await tester.ensureVisible(submit);
//     await tester.tap(submit);
//     await tester.pumpAndSettle();

//     expect(requested?['isTsumo'], false);
//     expect(requested?['ronPoints'], 2000);
//     expect(requested?['yakumanMultiplier'], 1);
//     expect(requested?['honba'], 0);
//   });

//   testWidgets('ツモでは親子の支払い額ペアをGridから選択できる', (tester) async {
//     Map<String, Object>? requested;
//     await tester.pumpWidget(MaterialApp(home: ScoreRequestPage(
//       players: players,
//       winnerUid: 'winner',
//       onRequest: ({required isTsumo, required ronPoints, required dealerPayment,
//         required nonDealerPayment, required yakumanMultiplier, required honba}) async {
//         requested = {
//           'isTsumo': isTsumo,
//           'ronPoints': ronPoints,
//           'dealerPayment': dealerPayment,
//           'nonDealerPayment': nonDealerPayment,
//           'yakumanMultiplier': yakumanMultiplier,
//         };
//       },
//     )));

//     await tester.tap(find.text('ツモ'));
//     await tester.pumpAndSettle();
//     final tsumoChoice = find.ancestor(
//       of: find.text('300 / 500'),
//       matching: find.byType(InkWell),
//     ).first;
//     await tester.ensureVisible(tsumoChoice);
//     await tester.tap(tsumoChoice);
//     await tester.pump();

//     final submit = find.text('点数請求');
//     await tester.ensureVisible(submit);
//     await tester.tap(submit);
//     await tester.pumpAndSettle();

//     expect(requested?['isTsumo'], true);
//     expect(requested?['dealerPayment'], 500);
//     expect(requested?['nonDealerPayment'], 300);
//   });

//   testWidgets('役満Gridで倍率を選択できる', (tester) async {
//     Map<String, Object>? requested;
//     await tester.pumpWidget(MaterialApp(home: ScoreRequestPage(
//       players: players,
//       winnerUid: 'winner',
//       onRequest: ({required isTsumo, required ronPoints, required dealerPayment,
//         required nonDealerPayment, required yakumanMultiplier, required honba}) async {
//         requested = {
//           'isTsumo': isTsumo,
//           'ronPoints': ronPoints,
//           'dealerPayment': dealerPayment,
//           'nonDealerPayment': nonDealerPayment,
//           'yakumanMultiplier': yakumanMultiplier,
//         };
//       },
//     )));

//     final yakumanChoice = find.ancestor(
//       of: find.text('2倍役満'),
//       matching: find.byType(InkWell),
//     );
//     await tester.ensureVisible(yakumanChoice);
//     await tester.tap(yakumanChoice);
//     await tester.pump();

//     final submit = find.text('点数請求');
//     await tester.ensureVisible(submit);
//     await tester.tap(submit);
//     await tester.pumpAndSettle();

//     expect(requested?['yakumanMultiplier'], 2);
//     expect(requested?['ronPoints'], 64000);
//   });
//   testWidgets('本場を増減でき、点数選択肢には本場点を加算せず請求時に本場数を渡す', (tester) async {
//     Map<String, Object>? requested;
//     await tester.pumpWidget(MaterialApp(home: ScoreRequestPage(
//       players: players,
//       winnerUid: 'winner',
//       honba: 2,
//       onRequest: ({required isTsumo, required ronPoints, required dealerPayment,
//         required nonDealerPayment, required yakumanMultiplier, required honba}) async {
//         requested = {'ronPoints': ronPoints, 'honba': honba};
//       },
//     )));

//     expect(find.text('2 本場'), findsOneWidget);
//     expect(find.text('2,000点'), findsOneWidget);
//     await tester.tap(find.byIcon(Icons.add));
//     await tester.pump();
//     expect(find.text('3 本場'), findsOneWidget);
//     expect(find.text('2,000点'), findsOneWidget);
//     await tester.tap(find.byIcon(Icons.remove));
//     await tester.pump();
//     expect(find.text('2 本場'), findsOneWidget);

//     final choice = find.ancestor(
//       of: find.text('2,000点'),
//       matching: find.byType(InkWell),
//     ).first;
//     await tester.ensureVisible(choice);
//     await tester.tap(choice);
//     await tester.pump();
//     final submit = find.text('点数請求');
//     await tester.ensureVisible(submit);
//     await tester.tap(submit);
//     await tester.pumpAndSettle();

//     expect(requested?['ronPoints'], 2000);
//     expect(requested?['honba'], 2);
//   });

// }
