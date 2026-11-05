import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// アプリケーション側で扱うログインユーザー情報。
class TableUser {
  const TableUser({
    required this.uid,
    this.displayName,
    this.email,
  });

  final String uid;
  final String? displayName;
  final String? email;
}

/// 卓登録に必要な認証情報を提供するインターフェース。
abstract interface class TableAuth {
  TableUser? get currentUser;
}

/// 卓データの保存先を抽象化するインターフェース。
abstract interface class TableStore {
  Future<String> addTable(Map<String, dynamic> data);
}

class FirebaseTableAuth implements TableAuth {
  FirebaseTableAuth({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  @override
  TableUser? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    return TableUser(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
    );
  }
}

class FirestoreTableStore implements TableStore {
  FirestoreTableStore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<String> addTable(Map<String, dynamic> data) async {
    final document = await _firestore.collection('tables').add(data);
    return document.id;
  }
}

class TableRepository {
  TableRepository({
    TableAuth? auth,
    TableStore? store,
  })  : _auth = auth ?? FirebaseTableAuth(),
        _store = store ?? FirestoreTableStore();

  final TableAuth _auth;
  final TableStore _store;

  Future<String> createTable({
    required String name,
    required int playerCount,
    required Map<String, dynamic> settings,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('卓を作成するにはログインが必要です。');
    }

    return _store.addTable({
      'name': name.trim(),
      'ownerUid': user.uid,
      'ownerName': user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : (user.email ?? 'ユーザー'),
      'playerCount': playerCount,
      'status': 'waiting',
      'settings': settings,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
