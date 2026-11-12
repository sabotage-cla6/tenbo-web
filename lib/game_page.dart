import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

const _ink = Color(0xFF18352E);
const _green = Color(0xFF245447);
const _gold = Color(0xFFD7B56D);
const _paper = Color(0xFFF7F5EF);

/// 対局中に点数・局情報・操作メニューを表示するトップ画面。
///
/// 点数更新などの対局処理は別機能として実装するため、
/// この画面では初期点数と表示用の操作メニューを提供する。
class GamePage extends StatelessWidget {
  const GamePage({
    required this.tableName,
    required this.playerCount,
    required this.players,
    required this.startingPoints,
    super.key,
  });

  final String tableName;
  final int playerCount;
  final Map<String, String?> players;
  final int startingPoints;

  static const _winds = ['東', '南', '西', '北'];

  void _showComingSoon(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action機能は準備中です。')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeWinds = _winds.take(playerCount == 3 ? 3 : 4).toList();
    final playerCards = <String, Widget>{
      for (final wind in activeWinds)
        wind: _PlayerCard(
          wind: wind,
          name: players[wind] ?? 'プレイヤー未設定',
          score: startingPoints,
          isDealer: wind == '東',
        ),
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _paper,
        foregroundColor: _ink,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '天棒',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3),
            ),
            Text(
              tableName,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '卓設定',
            onPressed: () => _showComingSoon(context, '卓設定'),
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.circle, size: 8, color: _green),
                        const SizedBox(width: 8),
                        const Text(
                          '対局中',
                          style: TextStyle(
                            color: _green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '配点: ${startingPoints.toString()}',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const RadialGradient(
                            colors: [Color(0xFF315F4A), Color(0xFF173B2C)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFF6B5638),
                            width: 6,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 16,
                              offset: Offset(0, 7),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Spacer(),
                                  Expanded(child: playerCards['北'] ?? const SizedBox()),
                                  const Spacer(),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(child: playerCards['東']!),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _RoundBoard(
                                      playerCount: playerCount,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(child: playerCards['西']!),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  const Spacer(),
                                  Expanded(child: playerCards['南']!),
                                  const Spacer(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ActionDock(
                      onAction: (action) => _showComingSoon(context, action),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '点数や局の進行などの操作は、今後の機能追加で対応します。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black45, fontSize: 11),
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

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.wind,
    required this.name,
    required this.score,
    required this.isDealer,
  });

  final String wind;
  final String name;
  final int score;
  final bool isDealer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDealer ? _gold : const Color(0xFFC9D9CE),
          width: isDealer ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDealer ? _gold : const Color(0xFFE6EEE8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  wind,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (isDealer) ...[
                const SizedBox(width: 3),
                const Text(
                  '親',
                  style: TextStyle(
                    color: Color(0xFF9B6B1D),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              score.toString(),
              style: const TextStyle(
                color: _ink,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const Text(
            '±0',
            style: TextStyle(color: Colors.black45, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _RoundBoard extends StatelessWidget {
  const _RoundBoard({required this.playerCount});

  final int playerCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10291E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '東 1 局',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '0 本場',
            style: TextStyle(color: _gold, fontSize: 11),
          ),
          const SizedBox(height: 8),
          const Icon(Icons.horizontal_rule, color: Colors.white70, size: 22),
          const Text(
            '供託',
            style: TextStyle(color: Colors.white70, fontSize: 9),
          ),
          const Text(
            '0 点',
            style: TextStyle(
              color: _gold,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${playerCount}人麻雀',
            style: const TextStyle(color: Colors.white60, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _ActionDock extends StatelessWidget {
  const _ActionDock({required this.onAction});

  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    const actions = [
      _GameAction('リーチ', '1,000点供託', Icons.flash_on, Color(0xFFB87920)),
      _GameAction('和了', '和了点請求', Icons.emoji_events, Color(0xFFB84B42)),
      _GameAction('点棒移動', '沖和・特殊精算', Icons.swap_horiz, Color(0xFF34749A)),
      _GameAction('流局', 'ノーテン罰符', Icons.autorenew, Color(0xFF536879)),
      _GameAction('次局へ', '局・親更新', Icons.skip_next, Color(0xFF3E805A)),
      _GameAction('精算', '対局終了', Icons.flag, Color(0xFF80518E)),
    ];

    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: 8),
          Row(
            children: [
              for (var column = 0; column < 3; column++) ...[
                if (column > 0) const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    action: actions[row * 3 + column],
                    onTap: () => onAction(actions[row * 3 + column].title),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _GameAction {
  const _GameAction(this.title, this.subtitle, this.icon, this.color);

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action, required this.onTap});

  final _GameAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: action.color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 11),
          child: Column(
            children: [
              Icon(action.icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                action.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                action.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
