import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// アプリケーション側で扱うログインユーザー情報。
class TableUser {
  const TableUser({required this.uid, this.displayName, this.email});

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

  factory TableInfo.fromDocument(String id, Map<String, dynamic> data) {
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

/// 卓の参加者情報。
class TableMember {
  const TableMember({
    required this.uid,
    required this.displayName,
    required this.isOwner,
  });

  final String uid;
  final String displayName;
  final bool isOwner;

  factory TableMember.fromDocument(
    String uid,
    Map<String, dynamic> data,
  ) {
    return TableMember(
      uid: uid,
      displayName: data['displayName'] as String? ?? 'ユーザー',
      isOwner: data['isOwner'] == true,
    );
  }
}

abstract interface class TableAuth {
  TableUser? get currentUser;
}

abstract interface class TableStore {
  Future<String> addTable(
    Map<String, dynamic> data, {
    required String ownerUid,
    required String ownerName,
  });
  Future<TableInfo?> findWaitingTableById(String tableId);
  Future<void> joinWaitingTable(
    String tableId, {
    required String uid,
    required String displayName,
  });
  Stream<List<TableMember>> watchMembers(String tableId);\n  Stream<Map<String, String?>> watchSeats(String tableId);\n  Future<void> assignSeat(String tableId, String wind, String uid);
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
  Future<String> addTable(
    Map<String, dynamic> data, {
    required String ownerUid,
    required String ownerName,
  }) async {
    final tableRef = _firestore.collection('tables').doc();
    final batch = _firestore.batch();
    batch.set(tableRef, data);
    batch.set(tableRef.collection('members').doc(ownerUid), {
      'uid': ownerUid,
      'displayName': ownerName,
      'isOwner': true,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return tableRef.id;
  }

  @override
  Future<TableInfo?> findWaitingTableById(String tableId) async {
    final document =
        await _firestore.collection('tables').doc(tableId).get();
    if (!document.exists) return null;
    final data = document.data();
    if (data == null || data['status'] != 'waiting') return null;
    return TableInfo.fromDocument(document.id, data);
  }

  @override
  Future<void> joinWaitingTable(
    String tableId, {
    required String uid,
    required String displayName,
  }) async {
    final tableRef = _firestore.collection('tables').doc(tableId);
    final memberRef = tableRef.collection('members').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final tableSnapshot = await transaction.get(tableRef);
      if (!tableSnapshot.exists || tableSnapshot.data()?['status'] != 'waiting') {
        throw StateError('参加できる卓が見つかりません。');
      }

      final memberSnapshot = await transaction.get(memberRef);
      if (memberSnapshot.exists) return;

      final tableData = tableSnapshot.data() ?? <String, dynamic>{};
      final capacity = (tableData['playerCount'] as num?)?.toInt() ?? 4;
      final memberCount = (tableData['memberCount'] as num?)?.toInt() ?? 1;
      if (memberCount >= capacity) {
        throw StateError('この卓は満員です。');
      }

      transaction.set(memberRef, {
        'uid': uid,
        'displayName': displayName,
        'isOwner': false,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(tableRef, {
        'memberCount': memberCount + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Stream<List<TableMember>> watchMembers(String tableId) {
    return _firestore
        .collection('tables')
        .doc(tableId)
        .collection('members')
        .orderBy('joinedAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TableMember.fromDocument(doc.id, doc.data()))
              .toList(),
        );
  }
}

class TableRepository {
  TableRepository({TableAuth? auth, TableStore? store})
      : _auth = auth ?? FirebaseTableAuth(),
        _store = store ?? FirestoreTableStore();

  final TableAuth _auth;
  final TableStore _store;\n\n  String? get currentUserUid => _auth.currentUser?.uid;

  String _displayName(TableUser user) {
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = user.email?.trim();
    if (email != null && email.isNotEmpty) return email;
    return 'ユーザー';
  }

  Future<String> createTable({
    required String name,
    required int playerCount,
    required Map<String, dynamic> settings,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('卓を作成するにはログインが必要です。');
    final ownerName = _displayName(user);
    return _store.addTable(
      {
        'name': name.trim(),
        'ownerUid': user.uid,
        'ownerName': ownerName,
        'playerCount': playerCount,
        'memberCount': 1,
        'status': 'waiting',
        'settings': settings,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      ownerUid: user.uid,
      ownerName: ownerName,
    );
  }

  Future<TableInfo?> findWaitingTableById(String tableId) async {
    if (_auth.currentUser == null) {
      throw StateError('卓に参加するにはログインが必要です。');
    }
    final normalizedTableId = tableId.trim();
    if (normalizedTableId.isEmpty) {
      throw ArgumentError.value(tableId, 'tableId', '卓IDを入力してください。');
    }
    return _store.findWaitingTableById(normalizedTableId);
  }

  Future<void> joinWaitingTable(String tableId) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('卓に参加するにはログインが必要です。');
    final normalizedTableId = tableId.trim();
    if (normalizedTableId.isEmpty) {
      throw ArgumentError.value(tableId, 'tableId', '卓IDを入力してください。');
    }
    await _store.joinWaitingTable(
      normalizedTableId,
      uid: user.uid,
      displayName: _displayName(user),
    );
  }

  Stream<List<TableMember>> watchMembers(String tableId) {
    if (_auth.currentUser == null) {
      return Stream.error(StateError('ロビーを表示するにはログインが必要です。'));
    }
    return _store.watchMembers(tableId);
  }
}
