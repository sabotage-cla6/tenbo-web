import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tenbo_web/table_repository.dart';

void main() {
  group('SeatArrangement.randomize', () {
    test('現在座っているプレイヤーだけをランダムな座順に割り当てる', () {
      const current = {
        'east': 'A',
        'south': 'B',
        'west': 'C',
        'north': 'D',
      };

      final result = SeatArrangement.randomize(
        current,
        4,
        random: Random(12),
      );

      expect(result.values.whereType<String>().toList()..sort(),
          ['A', 'B', 'C', 'D']);
      expect(result.values.whereType<String>().length, 4);
    });

    test('三人麻雀では北を空席にする', () {
      final result = SeatArrangement.randomize(
        const {
          'east': 'A',
          'south': 'B',
          'west': 'C',
          'north': null,
        },
        3,
        random: Random(12),
      );

      expect(result['north'], isNull);
      expect(result.values.whereType<String>().length, 3);
    });

    test('空席を詰めて座順を再設定し、待機メンバーを追加しない', () {
      final result = SeatArrangement.randomize(
        const {
          'east': 'A',
          'south': null,
          'west': 'C',
          'north': null,
        },
        4,
        random: Random(3),
      );

      expect({result['east'], result['south']}, {'A', 'C'});
      expect(result['east'], isNotNull);
      expect(result['south'], isNotNull);
      expect(result['west'], isNull);
      expect(result['north'], isNull);
    });
  });

  group('SeatArrangement.chooseDealer', () {
    test('起家に選んだ人を東にし、他のプレイヤーの順番を維持して回す', () {
      const current = {
        'east': 'A',
        'south': 'B',
        'west': 'C',
        'north': 'D',
      };

      final result = SeatArrangement.chooseDealer(
        current,
        4,
        random: Random(0),
      );

      final originalOrder = ['A', 'B', 'C', 'D'];
      final resultOrder = [
        result['east'],
        result['south'],
        result['west'],
        result['north'],
      ];
      final dealerIndex = originalOrder.indexOf(result['east']!);
      expect(resultOrder, [
        for (var offset = 0; offset < 4; offset++)
          originalOrder[(dealerIndex + offset) % 4],
      ]);
    });

    test('三人麻雀でも東を起点に三人の順番を維持する', () {
      final result = SeatArrangement.chooseDealer(
        const {
          'east': 'A',
          'south': 'B',
          'west': 'C',
          'north': null,
        },
        3,
        random: Random(4),
      );

      final order = [result['east'], result['south'], result['west']];
      expect(order.toSet(), {'A', 'B', 'C'});
      expect(result['north'], isNull);
    });

    test('対局者がいない場合はエラーにする', () {
      expect(
        () => SeatArrangement.chooseDealer(
          const {
            'east': null,
            'south': null,
            'west': null,
            'north': null,
          },
          4,
          random: Random(0),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
