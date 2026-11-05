// MockitoのMock基底クラスが持つ内部フィールドに関する警告を抑制する。
// ignore_for_file: must_be_immutable

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tenbo_web/table_repository.dart';

class MockTableAuth extends Mock implements TableAuth {}

class MockTableStore extends Mock implements TableStore {
  // Mockitoの引数マッチャー(any / captureAny)はnullを渡すため、
  // テスト用モックでは引数をnullableに広げて受け取る。
  @override
  Future<String> addTable(Map<String, dynamic>? data) =>
      super.noSuchMethod(
        Invocation.method(#addTable, [data]),
        returnValue: Future<String>.value(''),
      ) as Future<String>;
}

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
    when(store.addTable(any)).thenAnswer((_) async => 'table-123');
  });

  group('TableRepository.createTable', () {
    test('ログイン済みなら卓情報を保存して卓IDを返す', () async {
      final tableId = await repository.createTable(
        name: '  テスト卓  ',
        playerCount: 4,
        settings: {'startingPoints': 25000, 'allowNegativePoints': true},
      );

      expect(tableId, 'table-123');

      final savedData = verify(store.addTable(captureAny)).captured.single
          as Map<String, dynamic>;
      expect(savedData['name'], 'テスト卓');
      expect(savedData['ownerUid'], 'user-123');
      expect(savedData['ownerName'], 'テストユーザー');
      expect(savedData['playerCount'], 4);
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

      final savedData = verify(store.addTable(captureAny)).captured.single
          as Map<String, dynamic>;
      expect(savedData['ownerName'], 'test@example.com');
    });

    test('未ログインならStateErrorになり保存処理を呼び出さない', () async {
      when(auth.currentUser).thenReturn(null);

      await expectLater(
        repository.createTable(
          name: 'テスト卓',
          playerCount: 4,
          settings: const {},
        ),
        throwsA(isA<StateError>()),
      );

      verifyNever(store.addTable(any));
    });

    test('保存に失敗したら例外を呼び出し元へ伝える', () async {
      when(store.addTable(any)).thenThrow(Exception('Firestore error'));

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
}
