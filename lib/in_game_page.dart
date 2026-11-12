import 'package:flutter/material.dart';

const _ink = Color(0xFF18352E);
const _green = Color(0xFF245447);
const _gold = Color(0xFFD7B56D);
const _paper = Color(0xFFF7F5EF);

/// 対局中の卓・点数・操作メニューを表示するトップ画面。
/// 点数更新や局進行などの対局処理は、現段階では行わない。
class InGamePage extends StatelessWidget {
  const InGamePage({
    required this.tableName,
    required this.players,
    this.round = '東1局',
    this.honba = 0,
    this.kyotaku = 0,
    this.startingPoints = 25000,
    super.key,
  });

  final String tableName;
  final List<GamePlayer> players;
  final String round;
  final int honba;
  final int kyotaku;
  final int startingPoints;

  GamePlayer? _playerAt(String wind) {
    for (final player in players) {
      if (player.wind == wind) return player;
    }
    return null;
  }

  void _showAction(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(action + '機能は今後実装します。')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSanma = !players.any((player) => player.wind == '北');
    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        foregroundColor: _ink,
        titleSpacing: 20,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_esports, color: _gold, size: 26),
            SizedBox(width: 9),
            Text('天棒', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '卓設定',
            onPressed: () => _showAction(context, '卓設定'),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_paper, Color(0xFFECEFE9)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    _GameInfoBar(
                      tableName: tableName,
                      round: round,
                      startingPoints: startingPoints,
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final size = constraints.maxWidth;
                        return SizedBox(
                          width: size,
                          height: size,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFF251A12),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 14,
                                  offset: Offset(0, 7),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(7),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const RadialGradient(
                                    colors: [Color(0xFF174A35), Color(0xFF0B2A1C)],
                                  ),
                                  borderRadius: BorderRadius.circular(17),
                                  border: Border.all(color: const Color(0xFF76552F), width: 2),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(7),
                                  child: GridView.count(
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 7,
                                    crossAxisSpacing: 7,
                                    children: [
                                      const SizedBox.shrink(),
                                      _PlayerPanel(player: _playerAt('北')),
                                      const SizedBox.shrink(),
                                      _PlayerPanel(player: _playerAt('東')),
                                      _RoundPanel(round: round, honba: honba, kyotaku: kyotaku),
                                      _PlayerPanel(player: _playerAt('西')),
                                      const SizedBox.shrink(),
                                      _PlayerPanel(player: _playerAt('南'), isSelf: true),
                                      const SizedBox.shrink(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _ActionDock(onAction: (action) => _showAction(context, action)),
                    const SizedBox(height: 10),
                    Text(
                      isSanma ? '三人麻雀' : '四人麻雀',
                      style: const TextStyle(color: Colors.black45, fontSize: 11),
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
}

class GamePlayer {
  const GamePlayer({
    required this.wind,
    required this.name,
    required this.score,
    this.isDealer = false,
    this.isRiichi = false,
    this.isYakitori = false,
  });

  final String wind;
  final String name;
  final int score;
  final bool isDealer;
  final bool isRiichi;
  final bool isYakitori;
}

class _GameInfoBar extends StatelessWidget {
  const _GameInfoBar({
    required this.tableName,
    required this.round,
    required this.startingPoints,
  });

  final String tableName;
  final String round;
  final int startingPoints;

  String _format(int value) =>
      value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E1D7)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tableName, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _ink, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(round + '  •  配点 ' + _format(startingPoints) + '点',
                      style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.circle, size: 8, color: Color(0xFF4C9A69)),
            const SizedBox(width: 6),
            const Text('対局中', style: TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}

class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({required this.player, this.isSelf = false});

  final GamePlayer? player;
  final bool isSelf;

  String _format(int value) =>
      value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  @override
  Widget build(BuildContext context) {
    if (player == null) return const SizedBox.shrink();
    final diff = player!.score - 25000;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xE6193828),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: player!.isDealer
              ? const Color(0xFFE39A4A)
              : isSelf ? _gold : const Color(0xFF47765A),
          width: player!.isDealer || isSelf ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: player!.isDealer ? const Color(0xFFE39A4A) : Colors.white24,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(player!.wind,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(player!.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(_format(player!.score),
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          ),
          Text(
            (diff >= 0 ? '+' : '') + _format(diff),
            style: TextStyle(
              color: diff >= 0 ? const Color(0xFF73D69A) : const Color(0xFFFF9992),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 3,
            children: [
              if (player!.isRiichi) const _StatusTag(label: '⚡ 立直', color: Color(0xFFB93B35)),
              if (player!.isYakitori) const _StatusTag(label: '🍢 焼き鳥', color: Color(0xFFB85B2C)),
              if (player!.isDealer) const _StatusTag(label: '親', color: Color(0xFFB86D2D)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
      );
}

class _RoundPanel extends StatelessWidget {
  const _RoundPanel({required this.round, required this.honba, required this.kyotaku});

  final String round;
  final int honba;
  final int kyotaku;

  String _format(int value) =>
      value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xF20A2115),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _gold, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(round, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 4),
            Text(honba.toString() + ' 本場',
                style: const TextStyle(color: Color(0xFFF1C978), fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 7),
            const Icon(Icons.horizontal_rule, color: Colors.white, size: 20),
            const SizedBox(height: 2),
            const Text('供託', style: TextStyle(color: Colors.white60, fontSize: 9)),
            Text(_format(kyotaku) + '点',
                style: const TextStyle(color: Color(0xFFF1C978), fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      );
}

class _ActionDock extends StatelessWidget {
  const _ActionDock({required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    const actions = [
      _ActionItem('リーチ', '1,000点供託', Icons.bolt, Color(0xFFB97719)),
      _ActionItem('和了', '和了点請求', Icons.sports_martial_arts, Color(0xFFB9443D)),
      _ActionItem('点棒移動', '沖和・特殊精算', Icons.swap_horiz, Color(0xFF347BA5)),
      _ActionItem('流局', 'ノーテン罰符', Icons.autorenew, Color(0xFF526477)),
      _ActionItem('次局へ', '局・親更新', Icons.skip_next, Color(0xFF39865B)),
      _ActionItem('精算', '対局終了', Icons.flag_outlined, Color(0xFF80509A)),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.55,
      children: [
        for (final action in actions)
          Material(
            color: action.color,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => onAction(action.title),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(action.icon, color: Colors.white, size: 21),
                    const SizedBox(height: 3),
                    Text(action.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(action.subtitle, textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 9)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionItem {
  const _ActionItem(this.title, this.subtitle, this.icon, this.color);

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}
