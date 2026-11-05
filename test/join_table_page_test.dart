import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenbo_web/join_table_page.dart';
import 'package:tenbo_web/table_lobby_page.dart';
import 'package:tenbo_web/table_repository.dart';

void main() {
  group('JoinTablePage', () {
    testWidgets('卓名が空なら検索せず入力を促す', (tester) async {
      var searched = false;
      await tester.pumpWidget(
        MaterialApp(
          home: JoinTablePage(
            findTablesByName: (_) async {
              searched = true;
              return [];
            },
          ),
        ),
      );

      await tester.tap(find.text('卓に参加する'));
      await tester.pump();

      expect(searched, isFalse);
      expect(find.text('卓の名称を入力してください。'), findsOneWidget);
    });

    testWidgets('卓名が一致したら取得した卓情報でロビーへ遷移する',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JoinTablePage(
            findTablesByName: (name) async {
              expect(name, '金曜夜セット麻雀');
              return [
                const TableInfo(
                  id: 'table-123',
                  name: '金曜夜セット麻雀',
                  ownerName: '作成者',
                  playerCount: 4,
                  settings: {
                    'startingPoints': 25000,
                    'returnPoints': 30000,
                  },
                ),
              ];
            },
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '  金曜夜セット麻雀  ');
      await tester.tap(find.text('卓に参加する'));
      await tester.pumpAndSettle();

      expect(find.byType(TableLobbyPage), findsOneWidget);
      expect(find.text('金曜夜セット麻雀'), findsOneWidget);
      expect(find.text('table-123'), findsOneWidget);
      expect(find.text('作成者'), findsOneWidget);
    });

    testWidgets('該当する卓がなければロビーへ遷移しない', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: JoinTablePage(
            findTablesByName: (_) async => [],
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '存在しない卓');
      await tester.tap(find.text('卓に参加する'));
      await tester.pump();

      expect(find.byType(JoinTablePage), findsOneWidget);
      expect(find.byType(TableLobbyPage), findsNothing);
      expect(
        find.text('参加できる卓が見つかりません。卓名を確認してください。'),
        findsOneWidget,
      );
    });
  });
}
