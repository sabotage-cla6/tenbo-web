// MockitoのMock基底クラスが持つ内部フィールドに関する警告を抑制する。
// ignore_for_file: must_be_immutable

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tenbo_web/table_repository.dart';

class MockTableAuth extends Mock implements TableAuth {}

class MockTableStore extends Mock implements TableStore {
  @override
  Future<String> addTable(
    Map<String, dynamic>? data, {
    String? ownerUid,
    String? ownerName,
  }) =>
      super.noSuchMethod(
        Invocation.method(#addTable, [data], {
          #ownerUid: ownerUid,
          #ownerName: ownerName,
        }),
        returnValue: Future<String>.value(''),
      ) as Future<String>;

  @override
  Future<TableInfo?> findWaitingTableById(String? tableId) =>
      super.noSuchMethod(
        Invocation.method(#findWaitingTableById, [tableId]),
        returnValue: Future<TableInfo?>.value(null),
      ) as Future<TableInfo?>;

  @override
  Future<void> joinWaitingTable(
    String? tableId, {
    String? uid,
    String? displayName,
  }) =>
      super.noSuchMethod(
        Invocation.method(#joinWaitingTable, [tableId], {
          #uid: uid,
          #displayName: displayName,
        }),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Stream<List<TableMember>> watchMembers(String? tableId) =>
      super.noSuchMethod(
        Invocation.method(#watchMembers, [tableId]),
        returnValue: const Stream<List<TableMember>>.empty(),
      ) as Stream<List<TableMember>>;

  @override
  Stream<Map<String, String?>> watchSeats(String? tableId) =>
      super.noSuchMethod(
        Invocation.method(#watchSeats, [tableId]),
        returnValue: const Stream<Map<String, String?>>.empty(),
      ) as Stream<Map<String, String?>>;

  @override
  Future<void> randomizeSeats(String? tableId, int? playerCount, String? uid) =>
      super.noSuchMethod(
        Invocation.method(#randomizeSeats, [tableId, playerCount, uid]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> chooseDealer(String? tableId, int? playerCount, String? uid) =>
      super.noSuchMethod(
        Invocation.method(#chooseDealer, [tableId, playerCount, uid]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> assignSeat(String? tableId, String? wind, String? uid) =>
      super.noSuchMethod(
        Invocation.method(#assignSeat, [tableId, wind, uid]),
        returnValue: Future<void>.value(),
      ) as Future<void>;


void main() {
  late MockTableAuth auth;
  late MockTableStore store;
  late TableRepository repository;

  setUp(() {
    auth = MockTableAuth();
    store = MockTableStore();
    repository = TableRepository(auth: auth, store: store);

    when(auth.currentUser).thenReturn(
      const TableUser(
        uid: 'user-123',
        displayName: '  テストユーザー  ',
        email: 'test@example.com',
      ),
    );
    when(store.addTable(
      any,
      ownerUid: 'user-123',
      ownerName: 'テストユーザー',
    )).thenAnswer((_) async => 'table-123');
  });

  group('TableRepository.createTable', () {
    test('ログイン済みなら卓情報とオーナー情報を保存して卓IDを返す', () async {
      final tableId = await repository.createTable(
        name: '  テスト卓  ',
        playerCount: 4,
        settings: {'startingPoints': 25000, 'allowNegativePoints': true},
      );

      expect(tableId, 'table-123');
      final savedData = verify(store.addTable(
        captureAny,
        ownerUid: 'user-123',
        ownerName: 'テストユーザー',
      )).captured.single as Map<String, dynamic>;
      expect(savedData['name'], 'テスト卓');
      expect(savedData['ownerUid'], 'user-123');
      expect(savedData['ownerName'], 'テストユーザー');
      expect(savedData['playerCount'], 4);
      expect(savedData['memberCount'], 1);
      expect(savedData['seats'], {
        'east': null,
        'south': null,
        'west': null,
        'north': null,
      });
      expect(savedData['status'], 'waiting');
      expect(savedData['settings'], {
        'startingPoints': 25000,
        'allowNegativePoints': true,
      });
      expect(savedData['createdAt'], isNotNull);
      expect(savedData['updatedAt'], isNotNull);
    });

    test('表示名が空ならメールアドレスをownerNameに使う', () async {
      when(auth.currentUser).thenReturn(
        const TableUser(
          uid: 'user-123',
          displayName: '   ',
          email: 'test@example.com',
        ),
      );

      await repository.createTable(
        name: 'テスト卓',
        playerCount: 3,
        settings: const {},
      );

      verify(store.addTable(
        any,
        ownerUid: 'user-123',
        ownerName: 'test@example.com',
      )).called(1);
    });

    test('未ログインなら保存処理を呼び出さない', () async {
      when(auth.currentUser).thenReturn(null);

      await expectLater(
        repository.createTable(
          name: 'テスト卓',
          playerCount: 4,
          settings: const {},
        ),
        throwsA(isA<StateError>()),
      );

      verifyNever(store.addTable(
        any,
        ownerUid: anyNamed('ownerUid'),
        ownerName: anyNamed('ownerName'),
      ));
    });

    test('保存に失敗したら例外を呼び出し元へ伝える', () async {
      when(store.addTable(
        any,
        ownerUid: 'user-123',
        ownerName: 'テストユーザー',
      )).thenThrow(Exception('Firestore error'));

      await expectLater(
        repository.createTable(
          name: 'テスト卓',
          playerCount: 4,
          settings: const {},
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('TableRepository.findWaitingTableById', () {
    test('卓IDの前後の空白を除去して参加可能な卓を検索する', () async {
      const table = TableInfo(
        id: 'table-123',
        name: 'テスト卓',
        ownerName: '作成者',
        playerCount: 4,
        settings: {'startingPoints': 25000},
      );
      when(store.findWaitingTableById('table-123'))
          .thenAnswer((_) async => table);

      final result =
          await repository.findWaitingTableById('  table-123  ');

      expect(result, table);
      verify(store.findWaitingTableById('table-123')).called(1);
    });

    test('未ログインなら卓検索を行わない', () async {
      when(auth.currentUser).thenReturn(null);

      await expectLater(
        repository.findWaitingTableById('table-123'),
        throwsA(isA<StateError>()),
      );

      verifyNever(store.findWaitingTableById('table-123'));
    });

    test('卓IDが空なら検索せずArgumentErrorになる', () async {
      await expectLater(
        repository.findWaitingTableById('   '),
        throwsA(isA<ArgumentError>()),
      );

      verifyNever(store.findWaitingTableById(''));
    });
  });

  group('TableRepository.joinWaitingTable', () {
    test('ログイン中のユーザー情報を参加者として登録する', () async {
      await repository.joinWaitingTable('  table-123  ');

      verify(store.joinWaitingTable(
        'table-123',
        uid: 'user-123',
        displayName: 'テストユーザー',
      )).called(1);
    });

    test('表示名がなければメールアドレスを参加者名に使う', () async {
      when(auth.currentUser).thenReturn(
        const TableUser(uid: 'guest-1', email: 'guest@example.com'),
      );

      await repository.joinWaitingTable('table-123');

      verify(store.joinWaitingTable(
        'table-123',
        uid: 'guest-1',
        displayName: 'guest@example.com',
      )).called(1);
    });

    test('未ログインなら参加者登録を行わない', () async {
      when(auth.currentUser).thenReturn(null);

      await expectLater(
        repository.joinWaitingTable('table-123'),
        throwsA(isA<StateError>()),
      );

      verifyNever(store.joinWaitingTable(
        'table-123',
        uid: anyNamed('uid'),
        displayName: anyNamed('displayName'),
      ));
    });
  });


  group('TableRepository.assignSeat', () {
    test('ログイン中のユーザーを指定した座席へ割り当てる', () async {
      await repository.assignSeat('table-123', '北');

      verify(store.assignSeat('table-123', '北', 'user-123')).called(1);
    });

    test('未ログインなら座席を変更しない', () async {
      when(auth.currentUser).thenReturn(null);

      await expectLater(
        repository.assignSeat('table-123', '東'),
        throwsA(isA<StateError>()),
      );

      verifyNever(store.assignSeat(any, any, any));
    });
  });

  group('TableRepository起家決め', () {
    test('起家・場決めをログイン中ユーザーとしてStoreへ依頼する', () async {
      await repository.randomizeSeats('table-123', 4);
      verify(store.randomizeSeats('table-123', 4, 'user-123')).called(1);
    });

    test('起家決めをログイン中ユーザーとしてStoreへ依頼する', () async {
      await repository.chooseDealer('table-123', 3);
      verify(store.chooseDealer('table-123', 3, 'user-123')).called(1);
    });

    test('未ログインなら起家決めを依頼しない', () async {
      when(auth.currentUser).thenReturn(null);
      await expectLater(
        repository.chooseDealer('table-123', 4),
        throwsA(isA<StateError>()),
      );
      verifyNever(store.chooseDealer(any, any, any));
    });
  });
}
