import 'package:flutter/material.dart';

import 'in_game_page.dart';

/// 和了者が和了種別と点数を選択する画面。
class ScoreRequestPage extends StatefulWidget {
  const ScoreRequestPage({
    required this.players,
    required this.winnerUid,
    required this.onRequest,
    super.key,
  });

  final List<GamePlayer> players;
  final String winnerUid;
  final Future<void> Function({
    required bool isTsumo,
    required int ronPoints,
    required int dealerPayment,
    required int nonDealerPayment,
    required int yakumanMultiplier,
  }) onRequest;

  @override
  State<ScoreRequestPage> createState() => _ScoreRequestPageState();
}

class _ScoreRequestPageState extends State<ScoreRequestPage> {
  bool _isTsumo = false;
  int? _ronPoints;
  int? _dealerPayment;
  int? _nonDealerPayment;
  int _yakumanMultiplier = 2;
  bool _submitting = false;

  static const _ronChoices = <int>[1300, 2600, 5200, 1000, 2000, 3900, 7700, 8000, 12000, 16000, 24000, 32000];
  static const _tsumoChoices = <(int, int)>[
    (300, 500), (400, 700), (500, 1000), (700, 1300),
    (800, 1600), (1000, 2000), (1300, 2600), (1600, 3200),
    (2000, 3900), (3000, 6000), (4000, 8000), (6000, 12000),
  ];

  String _format(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',',
  );

  Future<void> _submit() async {
    if (_submitting) return;
    if (_isTsumo ? _dealerPayment == null : _ronPoints == null) return;
    setState(() => _submitting = true);
    try {
      await widget.onRequest(
        isTsumo: _isTsumo,
        ronPoints: _ronPoints ?? 0,
        dealerPayment: _dealerPayment ?? 0,
        nonDealerPayment: _nonDealerPayment ?? 0,
        yakumanMultiplier: _yakumanMultiplier,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    GamePlayer? winner;
    for (final player in widget.players) {
      if (player.uid == widget.winnerUid) winner = player;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('和了点数の請求')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
            Text('和了者：${winner?.name ?? '不明'}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    for (final player in widget.players)
                      Text('${player.wind} ${player.name}  ${_format(player.score)}点',
                        style: TextStyle(fontWeight: player.uid == widget.winnerUid ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('ロン')),
                ButtonSegment(value: true, label: Text('ツモ')),
              ],
              selected: {_isTsumo},
              onSelectionChanged: (values) => setState(() {
                _isTsumo = values.first;
                _ronPoints = null;
                _dealerPayment = null;
                _nonDealerPayment = null;
              }),
            ),
            const SizedBox(height: 18),
            if (!_isTsumo) ...[
              const Text('放銃者からの支払い点数', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final points in _ronChoices)
                  ChoiceChip(
                    label: Text('${_format(points)}点'),
                    selected: _ronPoints == points,
                    onSelected: (_) => setState(() => _ronPoints = points),
                  ),
              ]),
            ] else ...[
              const Text('親・子の支払い点数', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final pair in _tsumoChoices)
                  ChoiceChip(
                    label: Text('${_format(pair.$1)} / ${_format(pair.$2)}'),
                    selected: _dealerPayment == pair.$2 && _nonDealerPayment == pair.$1,
                    onSelected: (_) => setState(() {
                      _nonDealerPayment = pair.$1;
                      _dealerPayment = pair.$2;
                    }),
                  ),
              ]),
              if (_dealerPayment != null) ...[
                const SizedBox(height: 12),
                Text('親：${_format(_dealerPayment!)}点 ／ 子：${_format(_nonDealerPayment!)}点'),
                const Text('和了者が親の場合は、子3人が同額を支払います。'),
              ],
            ],
            const SizedBox(height: 18),
            const Text('役満', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(children: [
              const Text('倍率'),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _yakumanMultiplier,
                items: [for (var i = 2; i <= 6; i++) DropdownMenuItem(value: i, child: Text('$i倍役満'))],
                onChanged: (value) => setState(() => _yakumanMultiplier = value ?? 2),
              ),
            ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting || (_isTsumo ? _dealerPayment == null : _ronPoints == null)
                      ? null : _submit,
                  child: Text(_submitting ? '請求中…' : '支払いを依頼する'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
