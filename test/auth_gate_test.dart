import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tenbo_web/auth_gate.dart';
import 'package:tenbo_web/table_repository.dart';

import 'helpers/mock_table_repository.dart';

void main() {
  const playingTable = TableInfo(
    id: 'table-playing',
    name: '対局中の卓',
    ownerName: 'オーナー',
    playerCount: 4,
    settings: {'startingPoints': 25000},
  );

  testWidgets('対局中の卓がなければホーム画面を表示する', (tester) async {
    final repository = MockTableRepository();
    when(repository.findPlayingTableForUser('user-123'))
        .thenAnswer((_) async => null);

    await tester.pumpWidget(MaterialApp(
      home: AuthenticatedHomeGate(
        uid: 'user-123',
        repository: repository,
        homePage: const Scaffold(body: Text('ホーム画面')),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('ホーム画面'), findsOneWidget);
    verify(repository.findPlayingTableForUser('user-123')).called(1);
  });

  testWidgets('参加中の対局があれば対局画面へ自動復帰する', (tester) async {
    final repository = MockTableRepository();
    when(repository.findPlayingTableForUser('user-123'))
        .thenAnswer((_) async => playingTable);
    when(repository.watchMembers('table-playing')).thenAnswer(
      (_) => Stream.value(const [
        TableMember(uid: 'east-uid', displayName: '東家', isOwner: true),
        TableMember(uid: 'user-123', displayName: '南家', isOwner: false),
        TableMember(uid: 'west-uid', displayName: '西家', isOwner: false),
        TableMember(uid: 'north-uid', displayName: '北家', isOwner: false),
      ]),
    );
    when(repository.watchSeats('table-playing')).thenAnswer(
      (_) => Stream.value(const {
        '東': 'east-uid',
        '南': 'user-123',
        '西': 'west-uid',
        '北': 'north-uid',
      }),
    );
    when(repository.watchStatus('table-playing'))
        .thenAnswer((_) => Stream.value('playing'));
    when(repository.watchGameState('table-playing')).thenAnswer(
      (_) => Stream.value(const GameState(
        round: GameRound(wind: 'east', number: 1, honba: 0, seq: 1),
        kyotakuSticks: 0,
        players: {
          'east-uid': GamePlayerState(score: 25000, isRiichi: false),
          'user-123': GamePlayerState(score: 25000, isRiichi: false),
          'west-uid': GamePlayerState(score: 25000, isRiichi: false),
          'north-uid': GamePlayerState(score: 25000, isRiichi: false),
        },
      )),
    );

    await tester.pumpWidget(MaterialApp(
      home: AuthenticatedHomeGate(
        uid: 'south-uid',
        repository: repository,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('東1局'), findsOneWidget);
    expect(find.text('対局中'), findsOneWidget);
    verify(repository.findPlayingTableForUser('user-123')).called(1);
    verify(repository.watchGameState('table-playing')).called(1);
  });
}
