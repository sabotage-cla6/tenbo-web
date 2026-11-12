import 'dart:math';

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
  Stream<List<TableMember>> watchMembers(String tableId);
  Stream<Map<String, String?>> watchSeats(String tableId);
  Stream<String> watchStatus(String tableId);
  Future<void> startGame(String tableId, String uid);
  Future<void> assignSeat(String tableId, String wind, String uid);
  Future<void> randomizeSeats(String tableId, int playerCount, String uid);
  Future<void> chooseDealer(String tableId, int playerCount, String uid);
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
      final memberCount = (tableData['memberCount'] as num?)?.toInt() ?? 1;

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
  Stream<Map<String, String?>> watchSeats(String tableId) {
    return _firestore.collection('tables').doc(tableId).snapshots().map((snapshot) {
      final rawSeats = snapshot.data()?['seats'];
      final seats = rawSeats is Map ? rawSeats : const <String, dynamic>{};
      return {
        '東': seats['east'] as String?,
        '南': seats['south'] as String?,
        '西': seats['west'] as String?,
        '北': seats['north'] as String?,
      };
    });
  }

  @override
  Stream<String> watchStatus(String tableId) {
    return _firestore.collection('tables').doc(tableId).snapshots().map(
      (snapshot) => snapshot.data()?['status'] as String? ?? 'waiting',
    );
  }

  @override
  Future<void> startGame(String tableId, String uid) async {
    final tableRef = _firestore.collection('tables').doc(tableId);
    final memberRef = tableRef.collection('members').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final tableSnapshot = await transaction.get(tableRef);
      final memberSnapshot = await transaction.get(memberRef);
      if (!tableSnapshot.exists || tableSnapshot.data()?['status'] != 'waiting') {
        throw StateError('対局を開始できるロビーが見つかりません。');
      }
      if (!memberSnapshot.exists) {
        throw StateError('卓の参加者だけが対局を開始できます。');
      }

      final data = tableSnapshot.data()!;
      final playerCount = (data['playerCount'] as num?)?.toInt() ?? 4;
      final rawSeats = data['seats'];
      final seatFields = playerCount == 3
          ? const ['east', 'south', 'west']
          : const ['east', 'south', 'west', 'north'];
      final seatedUids = [
        for (final field in seatFields)
          if (rawSeats is Map && rawSeats[field] is String)
            rawSeats[field] as String,
      ];
      if (seatedUids.length != playerCount ||
          seatedUids.toSet().length != playerCount) {
        throw StateError('全員が着席してから対局を開始してください。');
      }
      if (!seatedUids.contains(uid)) {
        throw StateError('対局者だけが対局を開始できます。');
      }

      transaction.update(tableRef, {
        'status': 'playing',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> assignSeat(String tableId, String wind, String uid) async {
    const fieldByWind = {'東': 'east', '南': 'south', '西': 'west', '北': 'north'};
    final field = fieldByWind[wind];
    if (field == null) throw ArgumentError.value(wind, 'wind', '不正な座席です。');
    final tableRef = _firestore.collection('tables').doc(tableId);
    final memberRef = tableRef.collection('members').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final tableSnapshot = await transaction.get(tableRef);
      final memberSnapshot = await transaction.get(memberRef);
      if (!tableSnapshot.exists || tableSnapshot.data()?['status'] != 'waiting') {
        throw StateError('座席を変更できるロビーが見つかりません。');
      }
      if (!memberSnapshot.exists) {
        throw StateError('卓の参加者だけが対局者になれます。');
      }

      final data = tableSnapshot.data()!;
      final playerCount = (data['playerCount'] as num?)?.toInt() ?? 4;
      if (playerCount == 3 && wind == '北') {
        throw StateError('三人麻雀では北の席を使用できません。');
      }
      final rawSeats = data['seats'];
      final seats = <String, dynamic>{
        'east': rawSeats is Map ? rawSeats['east'] : null,
        'south': rawSeats is Map ? rawSeats['south'] : null,
        'west': rawSeats is Map ? rawSeats['west'] : null,
        'north': rawSeats is Map ? rawSeats['north'] : null,
      };
      if (seats[field] == uid) return;
      for (final key in seats.keys) {
        if (seats[key] == uid) seats[key] = null;
      }
      seats[field] = uid;
      transaction.update(tableRef, {
        'seats': seats,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }


  Future<void> _updateSeatArrangement(
    String tableId,
    String uid,
    int playerCount,
    Map<String, String?> Function(Map<String, String?> current) arrange,
  ) async {
    final tableRef = _firestore.collection('tables').doc(tableId);
    final memberRef = tableRef.collection('members').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final tableSnapshot = await transaction.get(tableRef);
      final memberSnapshot = await transaction.get(memberRef);
      if (!tableSnapshot.exists || tableSnapshot.data()?['status'] != 'waiting') {
        throw StateError('座席を変更できるロビーが見つかりません。');
      }
      if (!memberSnapshot.exists) {
        throw StateError('卓の参加者だけが起家を決められます。');
      }

      final data = tableSnapshot.data()!;
      final actualPlayerCount = (data['playerCount'] as num?)?.toInt() ?? 4;
      if (actualPlayerCount != playerCount) {
        throw StateError('卓の対局人数が変更されています。画面を更新してください。');
      }
      final rawSeats = data['seats'];
      final current = <String, String?>{
        'east': rawSeats is Map ? rawSeats['east'] as String? : null,
        'south': rawSeats is Map ? rawSeats['south'] as String? : null,
        'west': rawSeats is Map ? rawSeats['west'] as String? : null,
        'north': rawSeats is Map ? rawSeats['north'] as String? : null,
      };
      if (!current.values.contains(uid)) {
        throw StateError('起家を決めるには、先に対局者の席に入ってください。');
      }

      final nextSeats = arrange(current);
      transaction.update(tableRef, {
        'seats': nextSeats,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> randomizeSeats(String tableId, int playerCount, String uid) {
    return _updateSeatArrangement(
      tableId,
      uid,
      playerCount,
      (current) => SeatArrangement.randomize(current, playerCount),
    );
  }

  @override
  Future<void> chooseDealer(String tableId, int playerCount, String uid) {
    return _updateSeatArrangement(
      tableId,
      uid,
      playerCount,
      (current) => SeatArrangement.chooseDealer(current, playerCount),
    );
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


/// 東南西北の座席配置を計算する純粋ロジック。
class SeatArrangement {
  static const _winds = ['east', 'south', 'west', 'north'];

  static Map<String, String?> randomize(
    Map<String, String?> current,
    int playerCount, {
    Random? random,
  }) {
    final winds = _winds.take(playerCount == 3 ? 3 : 4).toList();
    final players = winds
        .map((wind) => current[wind])
        .whereType<String>()
        .toList()
      ..shuffle(random ?? Random());
    final result = <String, String?>{for (final wind in _winds) wind: null};
    for (var index = 0; index < players.length; index++) {
      result[winds[index]] = players[index];
    }
    return result;
  }

  static Map<String, String?> chooseDealer(
    Map<String, String?> current,
    int playerCount, {
    Random? random,
  }) {
    final winds = _winds.take(playerCount == 3 ? 3 : 4).toList();
    final result = {for (final wind in _winds) wind: current[wind]};
    final occupiedIndexes = [
      for (var index = 0; index < winds.length; index++)
        if (result[winds[index]] != null) index,
    ];
    if (occupiedIndexes.isEmpty) {
      throw StateError('起家を決めるには、先に対局者の席に入ってください。');
    }

    final dealerIndex = occupiedIndexes[(random ?? Random()).nextInt(occupiedIndexes.length)];
    final rotated = [
      for (var offset = 0; offset < winds.length; offset++)
        result[winds[(dealerIndex + offset) % winds.length]],
    ];
    for (var index = 0; index < winds.length; index++) {
      result[winds[index]] = rotated[index];
    }
    if (playerCount == 3) result['north'] = null;
    return result;
  }
}

class TableRepository {
  TableRepository({TableAuth? auth, TableStore? store})
      : _auth = auth ?? FirebaseTableAuth(),
        _store = store ?? FirestoreTableStore();

  final TableAuth _auth;
  final TableStore _store;

  String? get currentUserUid => _auth.currentUser?.uid;

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
        'seats': {'east': null, 'south': null, 'west': null, 'north': null},
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

  Stream<Map<String, String?>> watchSeats(String tableId) {
    if (_auth.currentUser == null) {
      return Stream.error(StateError('ロビーを表示するにはログインが必要です。'));
    }
    return _store.watchSeats(tableId);
  }

  Stream<String> watchStatus(String tableId) {
    if (_auth.currentUser == null) {
      return Stream.error(StateError('卓の状態を取得するにはログインが必要です。'));
    }
    return _store.watchStatus(tableId);
  }

  Future<void> startGame(String tableId) async {
    final uid = currentUserUid;
    if (uid == null) throw StateError('対局を開始するにはログインが必要です。');
    await _store.startGame(tableId, uid);
  }

  Future<void> assignSeat(String tableId, String wind) async {
    final uid = currentUserUid;
    if (uid == null) throw StateError('座席を変更するにはログインが必要です。');
    await _store.assignSeat(tableId, wind, uid);
  }

  Future<void> randomizeSeats(String tableId, int playerCount) async {
    final uid = currentUserUid;
    if (uid == null) throw StateError('起家を決めるにはログインが必要です。');
    await _store.randomizeSeats(tableId, playerCount, uid);
  }

  Future<void> chooseDealer(String tableId, int playerCount) async {
    final uid = currentUserUid;
    if (uid == null) throw StateError('起家を決めるにはログインが必要です。');
    await _store.chooseDealer(tableId, playerCount, uid);
  }
}
