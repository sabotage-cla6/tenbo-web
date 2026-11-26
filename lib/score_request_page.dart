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
    this.embedded = false,
    this.onCancel,
    this.onComplete,
    super.key,
  });

  final List<GamePlayer> players;
  final String winnerUid;
  final int startingPoints;
  final String round;
  final int honba;
  final bool embedded;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;
  final Future<void> Function({
    required bool isDealer,
    required bool isTsumo,
    required int ronPoints,
    required int dealerPayment,
    required int nonDealerPayment,
    required int yakumanMultiplier,
    required int honba,
  })
  onRequest;

  @override
  State<ScoreRequestPage> createState() => _ScoreRequestPageState();
}

class _ScoreRequestPageState extends State<ScoreRequestPage> {
  bool _isDealer = false;
  bool _isTsumo = false;
  int? _ronPoints;
  Point? _selectedPoint;
  int? _dealerPayment;
  int? _nonDealerPayment;
  int _yakumanMultiplier = 2;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final winner = widget.players.where((p) => p.uid == widget.winnerUid);
    _isDealer = winner.isNotEmpty && winner.first.isDealer;
  }

  String? get _selectedKey {
    if (_selectedPoint == null) return null;
    if (_selectedYakuman) return 'yakuman-$_yakumanMultiplier';
    if (_isTsumo) {
      return 'tsumo-${_selectedPoint!.tsumo!.$1}-${_selectedPoint!.tsumo!.$2}';
    }
    return _ronPoints == null ? null : 'ron-$_ronPoints';
  }

  bool _selectedYakuman = false;

  static const _requestPoints = <Point?>[
    // 20符
    null,
    Point(ronChild: 1300, ronDealer: 2000, tsumo: (400, 700)),
    Point(ronChild: 2600, ronDealer: 3900, tsumo: (700, 1300)),
    Point(ronChild: 5200, ronDealer: 7700, tsumo: (1300, 2600)),
    // 30符
    Point(ronChild: 1000, ronDealer: 1500, tsumo: (300, 500)),
    Point(ronChild: 2000, ronDealer: 2900, tsumo: (500, 1000)),
    Point(ronChild: 3900, ronDealer: 5800, tsumo: (1000, 2000)),
    Point(ronChild: 7700, ronDealer: 11600, tsumo: (2000, 3900)),
    // 50符
    Point(ronChild: 1600, ronDealer: 2400, tsumo: (400, 800)),
    Point(ronChild: 3200, ronDealer: 4800, tsumo: (800, 1600)),
    Point(ronChild: 6400, ronDealer: 9600, tsumo: (1600, 3200)),
    null,
    // 満貫以上
    Point(ronChild: 8000, ronDealer: 12000, tsumo: (2000, 4000)),
    Point(ronChild: 12000, ronDealer: 18000, tsumo: (3000, 6000)),
    Point(ronChild: 16000, ronDealer: 24000, tsumo: (4000, 8000)),
    Point(ronChild: 24000, ronDealer: 36000, tsumo: (6000, 12000)),
    // 役満
    Point(ronChild: 32000, ronDealer: 48000, tsumo: (8000, 16000)),
    YakumanPoint(yakumanMultiplier: 1),
    YakumanPoint(yakumanMultiplier: 2),
    null,
    // 70符
    Point(ronChild: 2300, ronDealer: 3400, tsumo: (600, 1200)),
    Point(ronChild: 4500, ronDealer: 6800, tsumo: (1200, 2300)),
    // 90符
    Point(ronChild: 2900, ronDealer: 4400, tsumo: (800, 1500)),
    Point(ronChild: 5800, ronDealer: 8700, tsumo: (1500, 2900)),
    // 110符
    null,
    Point(ronChild: 7100, ronDealer: 10600, tsumo: (1800, 3600)),
  ];

  String _format(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );

  Widget _pointCell({
    required String label,
    required Point point,
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

  Widget _multiplierYakumanpointCell({
    required String label,
    required Point point,
    required bool selected,
    required VoidCallback? onTap,
    bool emphasized = false,
  }) {
    return Material(
      color: selected ? _scoreGold : const Color(0xFF263D30),
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: () {
          setState(() => _selectedPoint = point);
        },
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

  Future<void> _showYakumanMultiplierDialog(Point point) async {
    var multiplier = _yakumanMultiplier < 2 ? 2 : _yakumanMultiplier;

    final selectedMultiplier = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF102619),
          title: const Text(
            '役満の倍率設定',
            style: TextStyle(
              color: _scoreGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: multiplier > 2
                    ? () => setDialogState(() => multiplier--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: Colors.white,
                disabledColor: Colors.white30,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '${multiplier}倍',
                  style: const TextStyle(
                    color: _scoreGold,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setDialogState(() => multiplier++),
                icon: const Icon(Icons.add_circle_outline),
                color: Colors.white,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'キャンセル',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(multiplier),
              style: FilledButton.styleFrom(
                backgroundColor: _scoreGold,
                foregroundColor: _scoreInk,
              ),
              child: const Text('決定'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || selectedMultiplier == null) return;

    setState(() {
      _selectedPoint = point;
      _selectedYakuman = true;
      _yakumanMultiplier = selectedMultiplier;
      _ronPoints = null;
      _dealerPayment = null;
      _nonDealerPayment = null;
    });
  }

  Widget _buildPointGrid() {
    final cells = <Widget>[];
    for (final row in _requestPoints) {
      Widget cell = const SizedBox.shrink();

      if (row != null) {
        String pointBtnLabel = '';
        // 役満
        if( row is  YakumanPoint){
          if(row.yakumanMultiplier > 1){
            pointBtnLabel = _selectedYakuman
                ? '${_yakumanMultiplier}倍役満'
                : '${row.yakumanMultiplier}倍役満';
            cell = _pointCell(
              label: pointBtnLabel,
              point: row,
              selected:
                  _selectedYakuman && 1 < _yakumanMultiplier,
              onTap: () => _showYakumanMultiplierDialog(row),
              emphasized: true,
            );
          } else {
            pointBtnLabel = '役満';
          cell = _pointCell(
            label: pointBtnLabel,
            point: row,
            selected: _selectedPoint == row,
            onTap: () {
              setState(() {
                _selectedYakuman = false;
                _selectedPoint = row;
                _ronPoints = _isTsumo
                    ? null
                    : (_isDealer ? row.ronDealer : row.ronChild);
                _dealerPayment = null;
                _nonDealerPayment = null;
              });
            },
            emphasized: true,
          );
          }
        }
        // それ以外
        else {
          if (_isTsumo) {
            if (_isDealer) {
              pointBtnLabel = '${_format(row.tsumo.$2)} all';
            } else {
              pointBtnLabel =
                  '${_format(row.tsumo.$1)} / ${_format(row.tsumo.$2)}';
            }
          } else {
            if (_isDealer) {
              pointBtnLabel = _format(row.ronDealer);
            } else {
              pointBtnLabel = _format(row.ronChild);
            }
          }
          cell = _pointCell(
            label: pointBtnLabel,
            point: row,
            selected: _selectedPoint == row,
            onTap: () {
              setState(() {
                _selectedYakuman = false;
                _selectedPoint = row;
                _ronPoints = _isTsumo
                    ? null
                    : (_isDealer ? row.ronDealer : row.ronChild);
                _dealerPayment = null;
                _nonDealerPayment = null;
              });
            },
            emphasized: true,
          );
        }
      }

      cells.add(cell);
    }
    return _grid(cells, 4);
  }

  Future<void> _submit() async {
    if (_submitting || _selectedKey == null) return;
    setState(() => _submitting = true);
    try {
      await widget.onRequest(
        isDealer: _isDealer,
        isTsumo: _isTsumo,
        ronPoints: _ronPoints ?? 0,
        dealerPayment: _isTsumo && _selectedPoint != null ? _selectedPoint!.tsumo.$2 : 0,
        nonDealerPayment: _isTsumo && _selectedPoint != null
            ? (_isDealer ? _selectedPoint!.tsumo.$2 : _selectedPoint!.tsumo.$1)
            : 0,
        yakumanMultiplier: _selectedYakuman ? _yakumanMultiplier : 1,
        honba: widget.honba,
      );
      if (mounted) {
        if (widget.embedded) {
          widget.onComplete?.call();
        } else {
          Navigator.of(context).pop();
        }
      }
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

    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 450),
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
                const Text('🀄', style: TextStyle(fontSize: 17)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '和了（上がり）点数入力',
                    style: TextStyle(
                      color: _scoreGold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF08140C),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF47765A)),
              ),
              child: Text(
                '${widget.round} ${widget.honba}本場',
                style: const TextStyle(
                  color: _scoreGold,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _settingGroup(
              label: '和了者の立場',
              child: Row(
                children: [
                  Expanded(
                    child: _modalChoice(
                      '親（東）',
                      selected: winner?.isDealer == true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _modalChoice(
                      '子',
                      selected: winner != null && !winner.isDealer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _settingGroup(
              label: '和了方式',
              child: Row(
                children: [
                  Expanded(
                    child: _modeButton(
                      'ロン',
                      selected: !_isTsumo,
                      onTap: () => setState(() {
                        _isTsumo = false;
                        _selectedYakuman = false;
                        _ronPoints = null;
                        _dealerPayment = null;
                        _nonDealerPayment = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _modeButton(
                      'ツモ',
                      selected: _isTsumo,
                      onTap: () => setState(() {
                        _isTsumo = true;
                        _selectedYakuman = false;
                        _ronPoints = null;
                        _dealerPayment = null;
                        _nonDealerPayment = null;
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '点数・役の選択',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF08140C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2C5E3D)),
              ),
              child: Column(children: [_buildPointGrid()]),
            ),
            if (_isTsumo && _dealerPayment != null && !_selectedYakuman) ...[
              const SizedBox(height: 8),
              Text(
                '親：${_format(_dealerPayment!)}点 ／ 子：${_format(_nonDealerPayment!)}点',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFF1C978),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _footerButton(
                    'キャンセル',
                    onPressed: _submitting
                        ? null
                        : (widget.onCancel ??
                              () => Navigator.of(context).pop()),
                    primary: false,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _footerButton(
                    _submitting ? '請求中…' : '点数請求',
                    onPressed: _submitting || _selectedKey == null
                        ? null
                        : _submit,
                    primary: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      // 対局画面のスクロール領域を親に一本化する。
      return content;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF050906),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _modeButton(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? const Color(0xFFF0A10B) : const Color(0xFF263D30),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _footerButton(
    String label, {
    required VoidCallback? onPressed,
    required bool primary,
  }) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: primary
            ? const Color(0xFFF0A10B)
            : const Color(0xFF263D30),
        foregroundColor: primary ? Colors.black : Colors.white,
        disabledBackgroundColor: const Color(0xFF263D30),
        disabledForegroundColor: Colors.white38,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
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
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing,
                  style: const TextStyle(color: Colors.white54, fontSize: 9),
                ),
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
      child: Text(
        label,
        style: TextStyle(
          color: selected ? _scoreInk : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class Point {
  final int ronChild;
  final int ronDealer;
  final (int, int) tsumo;

  const Point({
    required this.ronChild,
    required this.ronDealer,
    required this.tsumo,
  });
}

class YakumanPoint extends Point {
  final int yakumanMultiplier;

  const YakumanPoint({
    required this.yakumanMultiplier,
  }) : super(
        ronChild: yakumanMultiplier * 32000,
        ronDealer: yakumanMultiplier * 48000,
        tsumo: (8000 * yakumanMultiplier, 16000 * yakumanMultiplier),
      );
}
