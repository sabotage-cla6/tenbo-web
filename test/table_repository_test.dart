import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:tenbo_web/table_repository.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockUser extends Mock implements User {}

class MockTablesCollection
    extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockTableDocument
    extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late MockFirebaseAuth auth;
  late MockFirebaseFirestore firestore;
  late MockUser user;
  late MockTablesCollection tables;
  late MockTableDocument document;
  late TableRepository repository;

  setUp(() {
    auth = MockFirebaseAuth();
    firestore = MockFirebaseFirestore();
    user = MockUser();
    tables = MockTablesCollection();
    document = MockTableDocument();

    repository = TableRepository(firestore: firestore, auth: auth);

    when(auth.currentUser).thenReturn(user);
    when(user.uid).thenReturn('user-123');
    when(user.displayName).thenReturn('  テストユーザー  ');
    when(user.email).thenReturn('test@example.com');
    when(firestore.collection('tables')).thenReturn(tables);
    when(tables.add(any)).thenAnswer((_) async => document);
    when(document.id).thenReturn('table-123');
  });

  group('TableRepository.createTable', () {
    test('ログイン済みなら卓情報をFirestoreに保存して卓IDを返す', () async {
      final tableId = await repository.createTable(
        name: '  テスト卓  ',
        playerCount: 4,
        settings: {'startingPoints': 25000, 'allowNegativePoints': true},
      );

      expect(tableId, 'table-123');

      final savedData =
          verify(tables.add(captureAny)).captured.single
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
      expect(savedData['createdAt'], isA<FieldValue>());
      expect(savedData['updatedAt'], isA<FieldValue>());
      verify(firestore.collection('tables')).called(1);
    });

    test('表示名が空ならメールアドレスをownerNameに使う', () async {
      when(user.displayName).thenReturn('   ');

      await repository.createTable(
        name: 'テスト卓',
        playerCount: 3,
        settings: const {},
      );

      final savedData =
          verify(tables.add(captureAny)).captured.single
              as Map<String, dynamic>;
      expect(savedData['ownerName'], 'test@example.com');
    });

    test('未ログインならStateErrorを返しFirestoreには保存しない', () async {
      when(auth.currentUser).thenReturn(null);

      await expectLater(
        repository.createTable(
          name: 'テスト卓',
          playerCount: 4,
          settings: const {},
        ),
        throwsA(isA<StateError>()),
      );

      verifyNever(firestore.collection(any));
    });

    test('Firestoreの保存に失敗したら例外を呼び出し元へ伝える', () async {
      when(tables.add(any)).thenThrow(Exception('Firestore error'));

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
