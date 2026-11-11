import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenbo_web/table_lobby_page.dart';
import 'package:tenbo_web/table_repository.dart';

Widget buildLobby({
  int playerCount = 4,
  Stream<List<TableMember>>? membersStream,
}) {
  return MaterialApp(
    home: TableLobbyPage(
      tableId: 'table-123',
      tableName: 'テスト卓',
      playerCount: playerCount,
      ownerName: 'テストプレイヤー',
      membersStream: membersStream ?? Stream.value(const [
        TableMember(
          uid: 'owner-1',
          displayName: 'テストプレイヤー',
          isOwner: true,
        ),
      ]),
      settings: const {
        'startingPoints': 25000,
        'returnPoints': 30000,
        'uma': [30, 10, -10, -30],
        'honbaPoints': 300,
        'allowNegativePoints': true,
        'rounding': 'round',
      },
    ),
  );
}

void main() {
  group('TableLobbyPage', () {
    testWidgets('卓情報・ルール・オーナーを表示し、空席を待機表示にする',
        (tester) async {
      await tester.pumpWidget(buildLobby());

      expect(find.text('対局開始待ち'), findsOneWidget);
      expect(find.text('参加者募集中'), findsOneWidget);
      expect(find.text('テスト卓'), findsOneWidget);
      expect(find.text('卓ID'), findsOneWidget);
      expect(find.text('table-123'), findsOneWidget);
      expect(find.text('4人麻雀 ・ 25,000点持ち ・ 30,000点返し'), findsOneWidget);
      expect(find.text('テストプレイヤー'), findsOneWidget);
      expect(find.text('オーナー'), findsOneWidget);
      expect(find.text('1 / 4 人'), findsOneWidget);
      expect(find.text('参加者を待っています'), findsNWidgets(3));
      expect(find.text('東'), findsOneWidget);
      expect(find.text('南'), findsOneWidget);
      expect(find.text('西'), findsOneWidget);
      expect(find.text('北'), findsOneWidget);
    });


    testWidgets('Firestoreから届いた参加者を複数表示する', (tester) async {
      await tester.pumpWidget(
        buildLobby(
          membersStream: Stream.value(const [
            TableMember(
              uid: 'owner-1',
              displayName: 'テストプレイヤー',
              isOwner: true,
            ),
            TableMember(
              uid: 'guest-2',
              displayName: '参加者2',
              isOwner: false,
            ),
          ]),
        ),
      );
      await tester.pump();

      expect(find.text('2 / 4 人'), findsOneWidget);
      expect(find.text('テストプレイヤー'), findsOneWidget);
      expect(find.text('参加者2'), findsOneWidget);
      expect(find.text('参加者を待っています'), findsNWidgets(2));
    });

    testWidgets('三人麻雀では座席を3つだけ表示する', (tester) async {
      await tester.pumpWidget(buildLobby(playerCount: 3));

      expect(find.text('1 / 3 人'), findsOneWidget);
      expect(find.text('東'), findsOneWidget);
      expect(find.text('南'), findsOneWidget);
      expect(find.text('西'), findsOneWidget);
      expect(find.text('北'), findsNothing);
      expect(find.text('参加者を待っています'), findsNWidgets(2));
    });

    testWidgets('参加者が揃うまでは対局開始ボタンを無効にする',
        (tester) async {
      await tester.pumpWidget(buildLobby());

      final startButton = tester.widget<FilledButton>(
        find.widgetWithText(
          FilledButton,
          '参加者が揃うと対局を開始できます',
        ),
      );

      expect(startButton.onPressed, isNull);
    });

    testWidgets('退出ボタンで前の画面に戻る', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TableLobbyPage(
                          tableId: 'table-123',
                          tableName: 'テスト卓',
                          playerCount: 4,
                          ownerName: 'テストプレイヤー',
                          membersStream: Stream.value(const [
                            TableMember(
                              uid: 'owner-1',
                              displayName: 'テストプレイヤー',
                              isOwner: true,
                            ),
                          ]),
                          settings: {},
                        ),
                      ),
                    );
                  },
                  child: const Text('ロビーを開く'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ロビーを開く'));
      await tester.pumpAndSettle();
      expect(find.text('対局開始待ち'), findsOneWidget);

      final exitButton = find.text('ロビーから退出してホームに戻る');
      await tester.ensureVisible(exitButton);
      await tester.tap(exitButton);
      await tester.pumpAndSettle();

      expect(find.text('ロビーを開く'), findsOneWidget);
      expect(find.text('対局開始待ち'), findsNothing);
    });
  });
}
