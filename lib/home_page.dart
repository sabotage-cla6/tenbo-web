import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const _menuInk = Color(0xFF18352E);
const _menuGreen = Color(0xFF245447);
const _menuGold = Color(0xFFD7B56D);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const _ink = Color(0xFF18352E);
  static const _green = Color(0xFF245447);
  static const _gold = Color(0xFFD7B56D);
  static const _paper = Color(0xFFF7F5EF);

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } on FirebaseAuthException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログアウトできませんでした。もう一度お試しください。')),
      );
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature機能は準備中です。')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final playerName = user?.displayName?.trim();
    final greetingName =
        playerName == null || playerName.isEmpty ? 'プレイヤー' : playerName;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _paper,
        foregroundColor: _ink,
        titleSpacing: 24,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_esports, color: _gold, size: 28),
            SizedBox(width: 10),
            Text(
              '天棒',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'ログアウト',
              onPressed: () => _signOut(context),
              icon: const Icon(Icons.logout),
            ),
          ),
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
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greetingName さん、こんにちは！',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'リアル麻雀の点棒管理を、もっと手軽に。',
                      style: TextStyle(color: Colors.black54, fontSize: 15),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF183B32), Color(0xFF34705C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 520;
                          final message = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TENBO',
                                style: TextStyle(
                                  color: Color(0xFFE5CB91),
                                  fontSize: 11,
                                  letterSpacing: 2.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                '点棒のやり取りを、スマートに。',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '麻雀牌を使ったリアルな対局で、点棒の受け渡しの代わりに天棒を使って得点を管理しましょう。',
                                style: TextStyle(
                                  color: Colors.white70,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          );
                          if (compact) return message;
                          return Row(
                            children: [
                              Expanded(child: message),
                              const SizedBox(width: 24),
                              const Icon(
                                Icons.casino_outlined,
                                size: 104,
                                color: Color(0x66FFFFFF),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      '対局メニュー',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 650;
                        final primaryWidth = wide
                            ? (constraints.maxWidth - 14) / 2
                            : constraints.maxWidth;
                        final secondaryWidth = wide
                            ? (constraints.maxWidth - 14) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            SizedBox(
                              width: primaryWidth,
                              child: _MenuCard(
                                icon: Icons.add_circle_outline,
                                title: '卓を作成',
                                description: '新しい卓を作って、対局を始めます',
                                primary: true,
                                onTap: () => _showComingSoon(context, '卓の作成'),
                              ),
                            ),
                            SizedBox(
                              width: primaryWidth,
                              child: _MenuCard(
                                icon: Icons.groups_outlined,
                                title: '卓に参加',
                                description: '参加コードなどを使って卓に加わります',
                                primary: true,
                                onTap: () => _showComingSoon(context, '卓への参加'),
                              ),
                            ),
                            SizedBox(
                              width: secondaryWidth,
                              child: _MenuCard(
                                icon: Icons.bar_chart,
                                title: '成績を見る',
                                description: 'これまでの対局成績を確認します',
                                onTap: () => _showComingSoon(context, '成績表示'),
                              ),
                            ),
                            SizedBox(
                              width: secondaryWidth,
                              child: _MenuCard(
                                icon: Icons.person_outline,
                                title: 'アカウント',
                                description: user?.email ?? '登録情報を確認します',
                                onTap: () => _showComingSoon(context, 'アカウント管理'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    const Center(
                      child: Text(
                        'TENBO  •  リアル麻雀の点棒管理を、もっと手軽に。',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black45, fontSize: 12),
                      ),
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

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final background = primary ? _menuGreen : Colors.white;
    final foreground = primary ? Colors.white : _menuInk;
    final subtitle = primary ? Colors.white70 : Colors.black54;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: BoxConstraints(minHeight: primary ? 150 : 116),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: primary ? const Color(0xFF34705C) : const Color(0xFFE5E1D7),
            ),
            boxShadow: primary
                ? [
                    BoxShadow(
                      color: _menuGreen.withValues(alpha: 0.14),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: primary ? 54 : 48,
                height: primary ? 54 : 48,
                decoration: BoxDecoration(
                  color: primary
                      ? Colors.white.withValues(alpha: 0.14)
                      : const Color(0xFFEAF0EB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: primary ? _menuGold : _menuGreen,
                  size: primary ? 30 : 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: foreground,
                        fontSize: primary ? 19 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(
                        color: subtitle,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: primary ? Colors.white70 : Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
