import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenbo_web/join_table_page.dart';
import 'package:tenbo_web/table_lobby_page.dart';
import 'package:tenbo_web/table_repository.dart';

void main() {
  group('JoinTablePage', () {
    testWidgets('卓IDが空なら検索せず入力を促す', (tester) async {
      var searched = false;
      await tester.pumpWidget(
        MaterialApp(
          home: JoinTablePage(
            findTableById: (_) async {
              searched = true;
              return null;
            },
          ),
        ),
      );

      await tester.tap(find.text('卓に参加する'));
      await tester.pump();

      expect(searched, isFalse);
      expect(find.text('卓IDを入力してください。'), findsOneWidget);
    });

    testWidgets('卓IDが一致したら参加者登録後にロビーへ遷移する',
        (tester) async {
      var registeredTableId;
      await tester.pumpWidget(
        MaterialApp(
          home: JoinTablePage(
            registerMember: (tableId) async {
              registeredTableId = tableId;
            },
            currentUserUid: 'guest-2',
            seatsStream: Stream.value(const {'東': null, '南': null, '西': null, '北': null}),
            membersStream: Stream.value(const [
              TableMember(uid: 'owner-1', displayName: '作成者', isOwner: true),
              TableMember(uid: 'guest-2', displayName: '参加者2', isOwner: false),
            ]),
            findTableById: (tableId) async {
              expect(tableId, 'table-123');
              return const TableInfo(
                id: 'table-123',
                name: '金曜夜セット麻雀',
                ownerName: '作成者',
                playerCount: 4,
                settings: {
                  'startingPoints': 25000,
                  'returnPoints': 30000,
                },
              );
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '  table-123  ');
      await tester.tap(find.text('卓に参加する'));
      await tester.pumpAndSettle();

      expect(registeredTableId, 'table-123');
      expect(find.byType(TableLobbyPage), findsOneWidget);
      expect(find.text('金曜夜セット麻雀'), findsOneWidget);
      expect(find.text('table-123'), findsOneWidget);
      expect(find.text('作成者'), findsOneWidget);
      expect(find.text('参加者2'), findsOneWidget);
    });

    testWidgets('該当する卓がなければロビーへ遷移しない', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JoinTablePage(
            findTableById: (_) async => null,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'unknown-table-id');
      await tester.tap(find.text('卓に参加する'));
      await tester.pump();

      expect(find.byType(JoinTablePage), findsOneWidget);
      expect(find.byType(TableLobbyPage), findsNothing);
      expect(
        find.text('参加できる卓が見つかりません。卓IDを確認してください。'),
        findsOneWidget,
      );
    });
  });
}
