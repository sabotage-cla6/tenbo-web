import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenbo_web/table_lobby_page.dart';
import 'package:tenbo_web/table_repository.dart';

Widget buildLobby({
  int playerCount = 4,
  Stream<List<TableMember>>? membersStream,
  Stream<Map<String, String?>>? seatsStream,
  Future<void> Function(String wind)? assignSeat,
  String currentUserUid = 'owner-1',
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
      seatsStream: seatsStream ?? Stream.value(const {
        '東': null,
        '南': null,
        '西': null,
        '北': null,
      }),
      currentUserUid: currentUserUid,
      assignSeat: assignSeat,
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
      expect(find.text('参加者 1人'), findsOneWidget);
      expect(find.text('空席（クリックして参加）'), findsNWidgets(4));
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

      expect(find.text('参加者 2人'), findsOneWidget);
      expect(find.text('テストプレイヤー'), findsOneWidget);
      expect(find.text('参加者2'), findsOneWidget);
      expect(find.text('空席（クリックして参加）'), findsNWidgets(4));
    });

    testWidgets('5人以上の参加者も一覧にすべて表示する', (tester) async {
      await tester.pumpWidget(
        buildLobby(
          membersStream: Stream.value(const [
            TableMember(uid: 'owner-1', displayName: 'A', isOwner: true),
            TableMember(uid: 'b', displayName: 'B', isOwner: false),
            TableMember(uid: 'c', displayName: 'C', isOwner: false),
            TableMember(uid: 'd', displayName: 'D', isOwner: false),
            TableMember(uid: 'e', displayName: 'E', isOwner: false),
          ]),
        ),
      );
      await tester.pump();

      expect(find.text('参加者 5人'), findsOneWidget);
      for (final name in ['A', 'B', 'C', 'D', 'E']) {
        expect(find.text(name), findsOneWidget);
      }
    });

    testWidgets('三人麻雀では座席を3つだけ表示する', (tester) async {
      await tester.pumpWidget(buildLobby(playerCount: 3));

      expect(find.text('参加者 1人'), findsOneWidget);
      expect(find.text('東'), findsOneWidget);
      expect(find.text('南'), findsOneWidget);
      expect(find.text('西'), findsOneWidget);
      expect(find.text('北'), findsNothing);
      expect(find.text('空席（クリックして参加）'), findsNWidgets(3));
    });

    testWidgets('座席をクリックすると自分をその方角へ割り当てる', (tester) async {
      String? selectedWind;
      await tester.pumpWidget(
        buildLobby(assignSeat: (wind) async {
          selectedWind = wind;
        }),
      );

      await tester.tap(find.text('空席（クリックして参加）').first);
      await tester.pump();

      expect(selectedWind, '東');
    });

    testWidgets('他の人が座っている席をクリックして交代できる', (tester) async {
      String? selectedWind;
      await tester.pumpWidget(
        buildLobby(
          membersStream: Stream.value(const [
            TableMember(uid: 'owner-1', displayName: 'テストプレイヤー', isOwner: true),
            TableMember(uid: 'guest-2', displayName: '参加者2', isOwner: false),
          ]),
          seatsStream: Stream.value(const {
            '東': 'guest-2',
            '南': null,
            '西': null,
            '北': null,
          }),
          assignSeat: (wind) async {
            selectedWind = wind;
          },
        ),
      );
      await tester.pump();

      await tester.tap(find.text('参加者2'));
      await tester.pump();

      expect(selectedWind, '東');
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
                          currentUserUid: 'owner-1',
                          seatsStream: Stream.value(const {'東': null, '南': null, '西': null, '北': null}),
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
