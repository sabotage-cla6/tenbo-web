// Mockito の Mock 基底クラスが持つ内部フィールドに関する警告を抑制する。
// ignore_for_file: must_be_immutable

import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:tenbo_web/table_repository.dart';

class MockTableRepository extends Mock implements TableRepository {
  @override
  String? get currentUserUid => super.noSuchMethod(
        Invocation.getter(#currentUserUid),
        returnValue: null,
      ) as String?;

  @override
  Future<TableInfo?> findPlayingTableForCurrentUser() => super.noSuchMethod(
        Invocation.method(#findPlayingTableForCurrentUser, []),
        returnValue: Future<TableInfo?>.value(null),
      ) as Future<TableInfo?>;

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
  Stream<String> watchStatus(String? tableId) => super.noSuchMethod(
        Invocation.method(#watchStatus, [tableId]),
        returnValue: const Stream<String>.empty(),
      ) as Stream<String>;

  @override
  Stream<GameState> watchGameState(String? tableId) => super.noSuchMethod(
        Invocation.method(#watchGameState, [tableId]),
        returnValue: const Stream<GameState>.empty(),
      ) as Stream<GameState>;

  @override
  Future<void> toggleRiichi(String? tableId) => super.noSuchMethod(
        Invocation.method(#toggleRiichi, [tableId]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> startGame(String? tableId) => super.noSuchMethod(
        Invocation.method(#startGame, [tableId]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> assignSeat(String? tableId, String? wind) => super.noSuchMethod(
        Invocation.method(#assignSeat, [tableId, wind]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> randomizeSeats(String? tableId, int? playerCount) =>
      super.noSuchMethod(
        Invocation.method(#randomizeSeats, [tableId, playerCount]),
        returnValue: Future<void>.value(),
      ) as Future<void>;

  @override
  Future<void> chooseDealer(String? tableId, int? playerCount) =>
      super.noSuchMethod(
        Invocation.method(#chooseDealer, [tableId, playerCount]),
        returnValue: Future<void>.value(),
      ) as Future<void>;
}
