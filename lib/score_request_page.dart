import 'package:flutter/material.dart';

import 'in_game_page.dart';

const _scoreInk = Color(0xFF18352E);
const _scoreGreen = Color(0xFF174A35);
const _scoreGold = Color(0xFFD7B56D);
const _scorePaper = Color(0xFFF7F5EF);

/// 和了者が和了種別と点数を選択する画面。
class ScoreRequestPage extends StatefulWidget {
  const ScoreRequestPage({
    required this.players,
    required this.winnerUid,
    required this.onRequest,
    this.startingPoints = 25000,
    this.round = '東1局',
    this.honba = 0,
    super.key,
  });

  final List<GamePlayer> players;
  final String winnerUid;
  final int startingPoints;
  final String round;
  final int honba;
  final Future<void> Function({
    required bool isTsumo,
    required int ronPoints,
    required int dealerPayment,
    required int nonDealerPayment,
    required int yakumanMultiplier,
    required int honba,
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
  late int _honba;

  @override
  void initState() {
    super.initState();
    _honba = widget.honba;
  }

  String? get _selectedKey {
    if (_selectedYakuman) return 'yakuman-$_yakumanMultiplier';
    if (_isTsumo) {
      if (_dealerPayment == null || _nonDealerPayment == null) return null;
      return 'tsumo-$_nonDealerPayment-$_dealerPayment';
    }
    return _ronPoints == null ? null : 'ron-$_ronPoints';
  }

  bool _selectedYakuman = false;

  static const _fuRows = <({
    String label,
    int? ronOne,
    int? ronTwo,
    (int, int)? tsumoOne,
    (int, int)? tsumoTwo,
  })>[
    (label: '20符', ronOne: null, ronTwo: 1300,
      tsumoOne: null, tsumoTwo: (400, 700)),
    (label: '30符', ronOne: 1000, ronTwo: 2000,
      tsumoOne: (300, 500), tsumoTwo: (500, 1000)),
    (label: '50符', ronOne: 1600, ronTwo: 3200,
      tsumoOne: (400, 800), tsumoTwo: (800, 1600)),
    (label: '70符', ronOne: 2300, ronTwo: 4500,
      tsumoOne: (600, 1200), tsumoTwo: (1200, 2300)),
  ];

  static const _limitRows = <({
    String label,
    int ron,
    (int, int) tsumo,
  })>[
    (label: '満貫', ron: 8000, tsumo: (2000, 4000)),
    (label: '跳満', ron: 12000, tsumo: (3000, 6000)),
    (label: '倍満', ron: 16000, tsumo: (4000, 8000)),
    (label: '三倍満', ron: 24000, tsumo: (6000, 12000)),
  ];

  String _format(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',',
  );

  void _selectRon(int points) {
    setState(() {
      _selectedYakuman = false;
      _ronPoints = points;
      _dealerPayment = null;
      _nonDealerPayment = null;
    });
  }

  void _selectTsumo((int, int) payment) {
    setState(() {
      _selectedYakuman = false;
      _ronPoints = null;
      _nonDealerPayment = payment.$1;
      _dealerPayment = payment.$2;
    });
  }

  void _selectYakuman(int multiplier) {
    setState(() {
      _selectedYakuman = true;
      _yakumanMultiplier = multiplier;
      _ronPoints = 32000 * multiplier;
      _nonDealerPayment = 8000 * multiplier;
      _dealerPayment = 16000 * multiplier;
    });
  }

  Widget _pointCell({
    required String label,
    required bool selected,
    required VoidCallback? onTap,
    bool emphasized = false,
  }) {
    return Material(
      color: selected ? _scoreGold : const Color(0xFF263D30),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected ? _scoreGold : const Color(0xFF263D30),
              width: selected ? 2 : 0,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                color: selected ? _scoreInk : Colors.white,
                fontSize: emphasized ? 13 : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _grid(List<Widget> children, int columns, {double ratio = 2.0}) {
    return GridView.count(
      crossAxisCount: columns,
      childAspectRatio: ratio,
      crossAxisSpacing: 6,
      mainAxisSpacing: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }

  Widget _buildFuGrid() {
    final cells = <Widget>[
      _pointCell(label: '符数', selected: false, onTap: null, emphasized: true),
      _pointCell(label: '1翻', selected: false, onTap: null, emphasized: true),
      _pointCell(label: '2翻', selected: false, onTap: null, emphasized: true),
    ];
    for (final row in _fuRows.take(3)) {
      cells.add(_pointCell(
        label: row.label, selected: false, onTap: null, emphasized: true,
      ));
      final one = _isTsumo ? row.tsumoOne : null;
      final two = _isTsumo ? row.tsumoTwo : null;
      cells.add((_isTsumo ? row.tsumoOne == null : row.ronOne == null)
          ? const SizedBox.shrink()
          : _pointCell(
              label: _isTsumo
                  ? '${_format(one!.$1)} / ${_format(one!.$2)}'
                  : '${_format(row.ronOne!)}点',
              selected: _isTsumo
                  ? _dealerPayment == one!.$2 && _nonDealerPayment == one!.$1
                  : _ronPoints == row.ronOne,
              onTap: () => _isTsumo ? _selectTsumo(one!) : _selectRon(row.ronOne!),
            ));
      cells.add(_pointCell(
        label: _isTsumo
            ? '${_format(two!.$1)} / ${_format(two!.$2)}'
            : '${_format(row.ronTwo!)}点',
        selected: _isTsumo
            ? _dealerPayment == two!.$2 && _nonDealerPayment == two!.$1
            : _ronPoints == row.ronTwo,
        onTap: () => _isTsumo ? _selectTsumo(two!) : _selectRon(row.ronTwo!),
      ));
    }
    return _grid(cells, 3);
  }

  Widget _buildLimitGrid() {
    return _grid([
      for (final row in _limitRows)
        _pointCell(
          label: _isTsumo
              ? '${_format(row.tsumo.$1)} / ${_format(row.tsumo.$2)}'
              : '${_format(row.ron)}点',
          selected: _isTsumo
              ? _dealerPayment == row.tsumo.$2 && _nonDealerPayment == row.tsumo.$1
              : _ronPoints == row.ron,
          onTap: () => _isTsumo ? _selectTsumo(row.tsumo) : _selectRon(row.ron),
        ),
    ], 4, ratio: 1.45);
  }

  Widget _buildYakumanGrid() {
    const choices = [(4, '4倍満'), (1, '役満'), (2, '2倍役満')];
    return _grid([
      for (final choice in choices)
        _pointCell(
          label: choice.$2,
          selected: _selectedYakuman && _yakumanMultiplier == choice.$1,
          onTap: () => _selectYakuman(choice.$1),
          emphasized: true,
        ),
    ], 3, ratio: 1.7);
  }

  Widget _buildSeventyFuGrid() {
    final row = _fuRows.last;
    final one = row.tsumoOne;
    final two = row.tsumoTwo;
    return _grid([
      _pointCell(label: row.label, selected: false, onTap: null, emphasized: true),
      _pointCell(
        label: _isTsumo ? '${_format(one!.$1)} / ${_format(one!.$2)}' : '${_format(row.ronOne!)}点',
        selected: _isTsumo
            ? _dealerPayment == one!.$2 && _nonDealerPayment == one!.$1
            : _ronPoints == row.ronOne,
        onTap: () => _isTsumo ? _selectTsumo(one!) : _selectRon(row.ronOne!),
      ),
      _pointCell(
        label: _isTsumo ? '${_format(two!.$1)} / ${_format(two!.$2)}' : '${_format(row.ronTwo!)}点',
        selected: _isTsumo
            ? _dealerPayment == two!.$2 && _nonDealerPayment == two!.$1
            : _ronPoints == row.ronTwo,
        onTap: () => _isTsumo ? _selectTsumo(two!) : _selectRon(row.ronTwo!),
      ),
    ], 3);
  }

  Widget _buildHighFuGrid() {
    final rows = [
      (label: '90符', ronOne: 2900, ronTwo: 5800,
        tsumoOne: (800, 1500), tsumoTwo: (1500, 2900)),
      (label: '110符', ronOne: 3600, ronTwo: 7100,
        tsumoOne: (900, 1800), tsumoTwo: (1800, 3600)),
    ];
    return _grid([
      for (final row in rows) ...[
        _pointCell(
          label: _isTsumo
              ? '${row.label} ${_format(row.tsumoOne.$1)} / ${_format(row.tsumoOne.$2)}'
              : '${row.label} ${_format(row.ronOne)}点',
          selected: _isTsumo
              ? _dealerPayment == row.tsumoOne.$2 && _nonDealerPayment == row.tsumoOne.$1
              : _ronPoints == row.ronOne,
          onTap: () => _isTsumo
              ? _selectTsumo(row.tsumoOne)
              : _selectRon(row.ronOne),
        ),
        _pointCell(
          label: _isTsumo
              ? '${row.label} ${_format(row.tsumoTwo.$1)} / ${_format(row.tsumoTwo.$2)}'
              : '${row.label} ${_format(row.ronTwo)}点',
          selected: _isTsumo
              ? _dealerPayment == row.tsumoTwo.$2 && _nonDealerPayment == row.tsumoTwo.$1
              : _ronPoints == row.ronTwo,
          onTap: () => _isTsumo
              ? _selectTsumo(row.tsumoTwo)
              : _selectRon(row.ronTwo),
        ),
      ],
    ], 4, ratio: 1.5);
  }

  Future<void> _submit() async {
    if (_submitting || _selectedKey == null) return;
    setState(() => _submitting = true);
    try {
      await widget.onRequest(
        isTsumo: _isTsumo,
        ronPoints: _ronPoints ?? 0,
        dealerPayment: _dealerPayment ?? 0,
        nonDealerPayment: _nonDealerPayment ?? 0,
        yakumanMultiplier: _selectedYakuman ? _yakumanMultiplier : 1,
        honba: _honba,
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
      backgroundColor: const Color(0xFF050906),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF102619),
                  border: Border.all(color: _scoreGold, width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Text('🀄',
                          style: TextStyle(fontSize: 17)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('和了（上がり）点数入力',
                            style: TextStyle(color: _scoreGold,
                              fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _settingGroup(
                      label: '和了者の立場',
                      child: Row(
                        children: [
                          Expanded(child: _modalChoice('親（東）',
                            selected: winner?.isDealer == true)),
                          const SizedBox(width: 8),
                          Expanded(child: _modalChoice('子',
                            selected: winner != null && !winner.isDealer)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _settingGroup(
                      label: '和了方式',
                      child: Row(
                        children: [
                          Expanded(child: _modeButton('ロン', selected: !_isTsumo,
                            onTap: () => setState(() {
                              _isTsumo = false;
                              _selectedYakuman = false;
                              _ronPoints = null;
                              _dealerPayment = null;
                              _nonDealerPayment = null;
                            }))),
                          const SizedBox(width: 8),
                          Expanded(child: _modeButton('ツモ', selected: _isTsumo,
                            onTap: () => setState(() {
                              _isTsumo = true;
                              _selectedYakuman = false;
                              _ronPoints = null;
                              _dealerPayment = null;
                              _nonDealerPayment = null;
                            }))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _settingGroup(
                      label: '本場',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF08140C),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF47765A)),
                        ),
                        child: Row(
                          children: [
                            _honbaButton(Icons.remove, () {
                              if (_honba > 0) setState(() => _honba--);
                            }, enabled: _honba > 0),
                            Expanded(
                              child: Text('$_honba 本場',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: _scoreGold,
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            _honbaButton(Icons.add, () => setState(() => _honba++)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('点数・役の選択',
                      style: TextStyle(color: Colors.white70,
                        fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF08140C),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2C5E3D)),
                      ),
                      child: Column(
                        children: [
                          _buildFuGrid(),
                          const SizedBox(height: 8),
                          _buildLimitGrid(),
                          const SizedBox(height: 8),
                          _buildYakumanGrid(),
                          const SizedBox(height: 8),
                          _buildSeventyFuGrid(),
                          const SizedBox(height: 8),
                          _buildHighFuGrid(),
                        ],
                      ),
                    ),
                    if (_isTsumo && _dealerPayment != null && !_selectedYakuman) ...[
                      const SizedBox(height: 8),
                      Text(
                        '親：${_format(_dealerPayment!)}点 ／ 子：${_format(_nonDealerPayment!)}点',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFF1C978),
                          fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _footerButton('キャンセル',
                            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                            primary: false),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _footerButton(_submitting ? '請求中…' : '点数請求',
                            onPressed: _submitting || _selectedKey == null ? null : _submit,
                            primary: true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeButton(String label, {required bool selected, required VoidCallback onTap}) {
    return Material(
      color: selected ? const Color(0xFFF0A10B) : const Color(0xFF263D30),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(color: selected ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _honbaButton(IconData icon, VoidCallback onTap, {bool enabled = true}) {
    return Material(
      color: const Color(0xFF263D30),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 36,
          height: 32,
          child: Icon(icon, color: enabled ? Colors.white : Colors.white30, size: 19),
        ),
      ),
    );
  }

  Widget _footerButton(String label, {required VoidCallback? onPressed, required bool primary}) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: primary ? const Color(0xFFF0A10B) : const Color(0xFF263D30),
        foregroundColor: primary ? Colors.black : Colors.white,
        disabledBackgroundColor: const Color(0xFF263D30),
        disabledForegroundColor: Colors.white38,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _settingGroup({
    required String label,
    required Widget child,
    String? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1D12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2C5E3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11))),
              if (trailing != null)
                Text(trailing,
                    style: const TextStyle(color: Colors.white54, fontSize: 9)),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Widget _modalChoice(String label, {required bool selected}) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      decoration: BoxDecoration(
        color: selected ? _scoreGold : const Color(0xFF263D30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected ? _scoreGold : const Color(0xFF47765A),
        ),
      ),
      child: Text(label,
          style: TextStyle(color: selected ? _scoreInk : Colors.white,
              fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

