import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tenbo_web/auth_gate.dart';
import 'package:tenbo_web/table_repository.dart';

import 'helpers/mock_table_repository.dart';

class _TestUser extends Fake implements User {
  @override
  String get uid => 'user-123';
}

void main() {
  testWidgets('ログイン後に自分が参加している対局中の卓へ遷移する',
      (WidgetTester tester) async {
    final repository = MockTableRepository();
    const activeTable = ActiveTableInfo(
      table: TableInfo(
        id: 'table-123',
        name: '再開する卓',
        ownerName: 'オーナー',
        playerCount: 4,
        settings: {'startingPoints': 25000},
      ),
      seats: {
        '東': 'user-2',
        '南': 'user-123',
        '西': 'user-3',
        '北': 'user-4',
      },
      members: [
        TableMember(uid: 'user-2', displayName: '東プレイヤー', isOwner: true),
        TableMember(uid: 'user-123', displayName: '自分', isOwner: false),
        TableMember(uid: 'user-3', displayName: '西プレイヤー', isOwner: false),
        TableMember(uid: 'user-4', displayName: '北プレイヤー', isOwner: false),
      ],
    );
    when(repository.findPlayingTableForCurrentUser())
        .thenAnswer((_) async => activeTable);
    when(repository.currentUserUid).thenReturn('user-123');

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          firebaseReady: true,
          authStateStream: Stream<User?>.value(_TestUser()),
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('再開する卓'), findsOneWidget);
    expect(find.text('自分'), findsOneWidget);
    expect(find.text('東プレイヤー'), findsOneWidget);
    expect(find.text('対局中'), findsOneWidget);
    verify(repository.findPlayingTableForCurrentUser()).called(1);
  });
}
