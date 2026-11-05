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

/// ロビー表示に必要な卓情報。
class TableInfo {
  const TableInfo({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.playerCount,
    required this.settings,
  });

  final String id;
  final String name;
  final String ownerName;
  final int playerCount;
  final Map<String, dynamic> settings;

  factory TableInfo.fromDocument(
    String id,
    Map<String, dynamic> data,
  ) {
    final rawSettings = data['settings'];
    return TableInfo(
      id: id,
      name: data['name'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? 'ユーザー',
      playerCount: data['playerCount'] is num
          ? (data['playerCount'] as num).toInt()
          : 4,
      settings: rawSettings is Map
          ? Map<String, dynamic>.from(rawSettings)
          : const <String, dynamic>{},
    );
  }
}

/// 卓登録・検索に必要な認証情報を提供するインターフェース。
abstract interface class TableAuth {
  TableUser? get currentUser;
}

/// 卓データの保存先を抽象化するインターフェース。
abstract interface class TableStore {
  Future<String> addTable(Map<String, dynamic> data);
  Future<List<TableInfo>> findWaitingTablesByName(String name);
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

  @override
  Future<List<TableInfo>> findWaitingTablesByName(String name) async {
    final snapshot = await _firestore
        .collection('tables')
        .where('name', isEqualTo: name)
        .where('status', isEqualTo: 'waiting')
        .limit(2)
        .get();

    return snapshot.docs
        .map((document) => TableInfo.fromDocument(
              document.id,
              document.data(),
            ))
        .toList();
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

  Future<List<TableInfo>> findWaitingTablesByName(String name) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('卓に参加するにはログインが必要です。');
    }

    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(name, 'name', '卓の名称を入力してください。');
    }

    return _store.findWaitingTablesByName(normalizedName);
  }
}
