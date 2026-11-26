import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 対局中の局情報。
class GameRound {
  const GameRound({required this.wind, required this.number, required this.honba, required this.seq});
  final String wind;
  final int number;
  final int honba;
  final int seq;
  factory GameRound.fromMap(Map<String, dynamic> data) => GameRound(
    wind: data['wind'] as String? ?? 'east',
    number: (data['number'] as num?)?.toInt() ?? 1,
    honba: (data['honba'] as num?)?.toInt() ?? 0,
    seq: (data['seq'] as num?)?.toInt() ?? 1,
  );
}
class GamePlayerState {
  const GamePlayerState({required this.score, required this.isRiichi});
  final int score;
  final bool isRiichi;
}
class GameState {
  const GameState({required this.round, required this.kyotakuSticks, required this.players, this.pendingWinnerUid, this.pendingPayments = const {}, this.pendingIsTsumo = false, this.pendingKyotaku = 0});
  final GameRound round;
  final int kyotakuSticks;
  final Map<String, GamePlayerState> players;
  final String? pendingWinnerUid;
  /// 支払者 UID ごとの未確定支払額（正の値）。
  final Map<String, int> pendingPayments;
  final bool pendingIsTsumo;
  final int pendingKyotaku;
  final bool hasPendingRoundAdvance;
  factory GameState.fromMap(Map<String, dynamic> data) {
    final rawRound = data['round'];
    final rawPlayers = data['players'];
    return GameState(
      round: GameRound.fromMap(rawRound is Map ? Map<String, dynamic>.from(rawRound) : const {}),
      kyotakuSticks: (data['kyotakuSticks'] as num?)?.toInt() ?? 0,
      pendingWinnerUid: data['pendingSettlement'] is Map ? (data['pendingSettlement'] as Map)['winnerUid'] as String? : null,
      pendingIsTsumo: data['pendingSettlement'] is Map && (data['pendingSettlement'] as Map)['isTsumo'] == true,
      pendingKyotaku: data['pendingSettlement'] is Map
          ? (((data['pendingSettlement'] as Map)['kyotakuAmount'] as num?)?.toInt() ?? 0)
          : 0,
      hasPendingRoundAdvance: data['roundAdvance'] is Map,
      pendingPayments: {
        if (data['pendingSettlement'] is Map && (data['pendingSettlement'] as Map)['payments'] is Map)
          for (final entry in ((data['pendingSettlement'] as Map)['payments'] as Map).entries)
            entry.key.toString(): (entry.value as num).toInt(),
      },
      players: {
        if (rawPlayers is Map)
          for (final entry in rawPlayers.entries)
            if (entry.value is Map)
              entry.key.toString(): GamePlayerState(
                score: ((entry.value as Map)['score'] as num?)?.toInt() ?? 0,
                isRiichi: (entry.value as Map)['isRiichi'] == true,
              ),
      },
    );
  }
}

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
  Future<TableInfo?> findPlayingTableForUser(String uid);
  Future<void> joinWaitingTable(
    String tableId, {
    required String uid,
    required String displayName,
  });
  Stream<List<TableMember>> watchMembers(String tableId);
  Stream<Map<String, String?>> watchSeats(String tableId);
  Stream<String> watchStatus(String tableId);
  Stream<GameState> watchGameState(String tableId);
  Future<void> toggleRiichi(String tableId, String uid);
  Future<void> createScoreRequest(String tableId, String winnerUid, Map<String, int> payments, bool isTsumo, int kyotakuAmount);
  Future<void> cancelScoreRequest(String tableId, String winnerUid);
  Future<void> confirmScorePayment(String tableId, String payerUid);
  Future<void> advanceRound(String tableId, String uid);
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
  Future<TableInfo?> findPlayingTableForUser(String uid) async {
    // メンバー情報を横断検索し、自分が着席している対局中の卓を探す。
    final memberSnapshots = await _firestore
        .collectionGroup('members')
        .where('uid', isEqualTo: uid)
        .get();

    for (final member in memberSnapshots.docs) {
      final tableRef = member.reference.parent.parent;
      if (tableRef == null) continue;

      final tableSnapshot = await tableRef.get();
      final data = tableSnapshot.data();
      final seats = data?['seats'];
      if (!tableSnapshot.exists ||
          data == null ||
          data['status'] != 'playing' ||
          seats is! Map ||
          !seats.values.contains(uid)) {
        continue;
      }

      return TableInfo.fromDocument(tableSnapshot.id, data);
    }
    return null;
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
  Stream<GameState> watchGameState(String tableId) {
    return _firestore.collection('tables').doc(tableId).snapshots().map((snapshot) {
      final rawGame = snapshot.data()?['game'];
      if (rawGame is! Map) throw StateError('対局情報を取得できません。');
      return GameState.fromMap(Map<String, dynamic>.from(rawGame));
    });
  }
  @override
  Future<void> toggleRiichi(String tableId, String uid) async {
    final tableRef = _firestore.collection('tables').doc(tableId);
    final memberRef = tableRef.collection('members').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final tableSnapshot = await transaction.get(tableRef);
      final memberSnapshot = await transaction.get(memberRef);
      if (!tableSnapshot.exists || tableSnapshot.data()?['status'] != 'playing') {
        throw StateError('対局中の卓が見つかりません。');
      }
      if (!memberSnapshot.exists) throw StateError('卓の参加者だけがリーチできます。');
      final data = tableSnapshot.data()!;
      final seats = data['seats'];
      if (seats is! Map || !seats.values.contains(uid)) throw StateError('対局者だけがリーチできます。');
      final rawGame = data['game'];
      if (rawGame is! Map) throw StateError('対局情報を取得できません。');
      final game = Map<String, dynamic>.from(rawGame);
      final rawPlayers = game['players'];
      if (rawPlayers is! Map || rawPlayers[uid] is! Map) throw StateError('プレイヤー情報を取得できません。');
      final players = Map<String, dynamic>.from(rawPlayers);
      final player = Map<String, dynamic>.from(players[uid] as Map);
      final score = (player['score'] as num?)?.toInt() ?? 0;
      final kyotaku = (game['kyotakuSticks'] as num?)?.toInt() ?? 0;

      if (player['isRiichi'] == true) {
        player['score'] = score + 1000;
        player['isRiichi'] = false;
        game['kyotakuSticks'] = kyotaku > 0 ? kyotaku - 1 : 0;
      } else {
        if (score < 1000) throw StateError('リーチには1,000点以上必要です。');
        player['score'] = score - 1000;
        player['isRiichi'] = true;
        game['kyotakuSticks'] = kyotaku + 1;
      }

      players[uid] = player;
      game['players'] = players;
      transaction.update(tableRef, {'game': game, 'updatedAt': FieldValue.serverTimestamp()});
    });
  }
  @override
  Future<void> createScoreRequest(String tableId, String winnerUid, Map<String, int> payments, bool isTsumo, int kyotakuAmount) async {
    final tableRef = _firestore.collection('tables').doc(tableId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(tableRef);
      final data = snapshot.data();
      if (!snapshot.exists || data?['status'] != 'playing') throw StateError('対局中の卓が見つかりません。');
      final gameRaw = data?['game'];
      if (gameRaw is! Map) throw StateError('対局情報を取得できません。');
      final game = Map<String, dynamic>.from(gameRaw);
      final playersRaw = game['players'];
      final seatsRaw = data?['seats'];
      if (playersRaw is! Map || !playersRaw.containsKey(winnerUid)) throw StateError('和了者の情報を取得できません。');
      if (seatsRaw is! Map || !seatsRaw.values.contains(winnerUid)) throw StateError('和了者の座席情報を取得できません。');
      if (game['pendingSettlement'] is Map || game['roundAdvance'] is Map) throw StateError('前の局の処理が完了していません。');
      final normalizedPayments = <String, int>{};
      for (final entry in payments.entries) {
        if (entry.key == winnerUid || !playersRaw.containsKey(entry.key) || entry.value <= 0) continue;
        normalizedPayments[entry.key] = entry.value;
      }
      if (normalizedPayments.isEmpty) throw StateError('支払対象のプレイヤーがいません。');
      game['pendingSettlement'] = {
        'winnerUid': winnerUid,
        'isTsumo': isTsumo,
        'payments': normalizedPayments,
        'kyotakuAmount': kyotakuAmount,
      };
      // 和了時点の親子関係を保持し、支払完了後の「次局へ」で利用する。
      game['roundAdvance'] = {
        'winnerUid': winnerUid,
        'dealerContinues': seatsRaw['east'] == winnerUid,
      };
      transaction.update(tableRef, {'game': game, 'updatedAt': FieldValue.serverTimestamp()});
    });
  }

  @override
  Future<void> cancelScoreRequest(String tableId, String winnerUid) async {
    final tableRef = _firestore.collection('tables').doc(tableId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(tableRef);
      final data = snapshot.data();
      if (!snapshot.exists || data?['status'] != 'playing') {
        throw StateError('対局中の卓が見つかりません。');
      }
      final gameRaw = data?['game'];
      if (gameRaw is! Map) throw StateError('対局情報を取得できません。');
      final game = Map<String, dynamic>.from(gameRaw);
      final settlementRaw = game['pendingSettlement'];
      if (settlementRaw == null) return;
      if (settlementRaw is! Map || settlementRaw['winnerUid'] != winnerUid) {
        throw StateError('自分が登録した点数請求だけを取り消せます。');
      }
      game.remove('pendingSettlement');
      game.remove('roundAdvance');
      transaction.update(tableRef, {'game': game, 'updatedAt': FieldValue.serverTimestamp()});
    });
  }

  @override
  Future<void> confirmScorePayment(String tableId, String payerUid) async {
    final tableRef = _firestore.collection('tables').doc(tableId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(tableRef);
      final data = snapshot.data();
      if (!snapshot.exists || data?['status'] != 'playing') throw StateError('対局中の卓が見つかりません。');
      final seats = data?['seats'];
      if (seats is! Map || !seats.values.contains(payerUid)) throw StateError('対局者だけが点数を支払えます。');
      final gameRaw = data?['game'];
      if (gameRaw is! Map) throw StateError('対局情報を取得できません。');
      final game = Map<String, dynamic>.from(gameRaw);
      final settlementRaw = game['pendingSettlement'];
      if (settlementRaw is! Map) throw StateError('確定待ちの点数請求はありません。');
      final settlement = Map<String, dynamic>.from(settlementRaw);
      final winnerUid = settlement['winnerUid'] as String?;
      final isTsumo = settlement['isTsumo'] == true;
      final paymentsRaw = settlement['payments'];
      if (winnerUid == null || paymentsRaw is! Map || !paymentsRaw.containsKey(payerUid)) {
        throw StateError('この支払は既に完了しているか、対象外です。');
      }
      final amount = (paymentsRaw[payerUid] as num).toInt();
      final kyotakuAmount = (settlement['kyotakuAmount'] as num?)?.toInt() ?? 0;
      final playersRaw = game['players'];
      if (playersRaw is! Map || playersRaw[payerUid] is! Map || playersRaw[winnerUid] is! Map) {
        throw StateError('プレイヤー情報を取得できません。');
      }
      final players = Map<String, dynamic>.from(playersRaw);
      final payer = Map<String, dynamic>.from(players[payerUid] as Map);
      final winner = Map<String, dynamic>.from(players[winnerUid] as Map);
      payer['score'] = ((payer['score'] as num?)?.toInt() ?? 0) - amount;
      final isFinalPayment = !isTsumo || paymentsRaw.length == 1;
      winner['score'] = ((winner['score'] as num?)?.toInt() ?? 0) + amount + (isFinalPayment ? kyotakuAmount : 0);
      players[payerUid] = payer;
      players[winnerUid] = winner;
      game['players'] = players;

      if (isTsumo) {
        final remaining = Map<String, dynamic>.from(paymentsRaw)..remove(payerUid);
        if (remaining.isEmpty) {
          game.remove('pendingSettlement');
          game['kyotakuSticks'] = 0;
        } else {
          settlement['payments'] = remaining;
          game['pendingSettlement'] = settlement;
        }
      } else {
        // ロンは最初に支払を確定した一人が全額を支払う。
        game.remove('pendingSettlement');
        game['kyotakuSticks'] = 0;
      }
      transaction.update(tableRef, {'game': game, 'updatedAt': FieldValue.serverTimestamp()});
    });
  }

  @override
  Future<void> advanceRound(String tableId, String uid) async {
    final tableRef = _firestore.collection('tables').doc(tableId);
    final memberRef = tableRef.collection('members').doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(tableRef);
      final memberSnapshot = await transaction.get(memberRef);
      final data = snapshot.data();
      if (!snapshot.exists || data?['status'] != 'playing') {
        throw StateError('対局中の卓が見つかりません。');
      }
      if (!memberSnapshot.exists) throw StateError('卓の参加者だけが次局へ進められます。');
      final rawSeats = data?['seats'];
      final rawGame = data?['game'];
      if (rawSeats is! Map || !rawSeats.values.contains(uid) || rawGame is! Map) {
        throw StateError('対局情報を取得できません。');
      }
      final game = Map<String, dynamic>.from(rawGame);
      if (game['pendingSettlement'] is Map) {
        throw StateError('点数の支払が完了してから次局へ進んでください。');
      }
      final advanceRaw = game['roundAdvance'];
      if (advanceRaw is! Map || advanceRaw['dealerContinues'] is! bool) {
        throw StateError('次局へ進める和了結果がありません。');
      }
      final roundRaw = game['round'];
      if (roundRaw is! Map) throw StateError('局情報を取得できません。');
      final round = Map<String, dynamic>.from(roundRaw);
      final seats = <String, dynamic>{
        'east': rawSeats['east'],
        'south': rawSeats['south'],
        'west': rawSeats['west'],
        'north': rawSeats['north'],
      };
      final playerCount = (data?['playerCount'] as num?)?.toInt() ?? 4;

      if (advanceRaw['dealerContinues'] == true) {
        round['honba'] = ((round['honba'] as num?)?.toInt() ?? 0) + 1;
      } else {
        const winds = ['east', 'south', 'west', 'north'];
        final currentWind = round['wind'] as String? ?? 'east';
        final windIndex = winds.indexOf(currentWind);
        if (windIndex < 0) throw StateError('場の情報が不正です。');
        final number = (round['number'] as num?)?.toInt() ?? 1;
        final maxNumber = playerCount == 3 ? 3 : 4;
        if (number < maxNumber) {
          round['number'] = number + 1;
        } else {
          round['number'] = 1;
          round['wind'] = winds[(windIndex + 1) % winds.length];
        }
        round['honba'] = 0;

        final previous = Map<String, dynamic>.from(seats);
        seats['east'] = previous['south'];
        seats['south'] = previous['west'];
        seats['west'] = playerCount == 3 ? previous['east'] : previous['north'];
        seats['north'] = playerCount == 3 ? null : previous['east'];
      }

      game['round'] = round;
      game.remove('roundAdvance');
      transaction.update(tableRef, {
        'seats': seats,
        'game': game,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
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

      final settings = data['settings'];
      final startingPoints = settings is Map ? (settings['startingPoints'] as num?)?.toInt() ?? 25000 : 25000;
      final initialPlayers = <String, dynamic>{
        for (final seatedUid in seatedUids) seatedUid: {'score': startingPoints, 'isRiichi': false},
      };
      transaction.update(tableRef, {
        'status': 'playing',
        'game': {
          'round': {'wind': 'east', 'number': 1, 'honba': 0, 'seq': 1},
          'kyotakuSticks': 0,
          'players': initialPlayers,
        },
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

  Future<TableInfo?> findPlayingTableForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('対局中の卓を確認するにはログインが必要です。');
    }
    return findPlayingTableForUser(user.uid);
  }

  /// 認証状態から受け取った UID を使って、参加中の対局を検索する。
  Future<TableInfo?> findPlayingTableForUser(String uid) {
    if (uid.isEmpty) {
      throw ArgumentError.value(uid, 'uid', 'ユーザーIDが空です。');
    }
    return _store.findPlayingTableForUser(uid);
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
    if (_auth.currentUser == null) return Stream.error(StateError('卓の状態を取得するにはログインが必要です。'));
    return _store.watchStatus(tableId);
  }
  Stream<GameState> watchGameState(String tableId) {
    if (_auth.currentUser == null) return Stream.error(StateError('対局情報を取得するにはログインが必要です。'));
    return _store.watchGameState(tableId);
  }
  Future<void> createScoreRequest(String tableId, {required String winnerUid, required Map<String, int> payments, required bool isTsumo, required int kyotakuAmount}) async {
    final uid = currentUserUid;
    if (uid == null) throw StateError('点数請求にはログインが必要です。');
    if (uid != winnerUid) throw StateError('和了者本人だけが点数請求できます。');
    await _store.createScoreRequest(tableId, winnerUid, payments, isTsumo, kyotakuAmount);
  }

  Future<void> cancelScoreRequest(String tableId) async {
    final uid = currentUserUid;
    if (uid == null) throw StateError('点数請求の取消にはログインが必要です。');
    await _store.cancelScoreRequest(tableId, uid);
  }

  Future<void> confirmScorePayment(String tableId) async {
    final uid = currentUserUid;
    if (uid == null) throw StateError('点数を支払うにはログインが必要です。');
    await _store.confirmScorePayment(tableId, uid);
  }

  Future<void> advanceRound(String tableId) async {
    final uid = currentUserUid;
    if (uid == null) throw StateError('次局へ進むにはログインが必要です。');
    await _store.advanceRound(tableId, uid);
  }

  Future<void> toggleRiichi(String tableId) async {
    final uid = currentUserUid;
    if (uid == null) throw StateError('リーチするにはログインが必要です。');
    await _store.toggleRiichi(tableId, uid);
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
