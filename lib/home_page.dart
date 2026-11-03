import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'create_table_page.dart';

const _menuInk = Color(0xFF18352E);
const _menuGreen = Color(0xFF245447);

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
                    const SizedBox(height: 24),
                    const Text(
                      '点棒のやり取りを、スマートに。',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '麻雀牌を使ったリアルな対局で、点棒の受け渡しの代わりに天棒を使って得点を管理しましょう。',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                        height: 1.6,
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
                        final cardWidth = wide
                            ? (constraints.maxWidth - 14) / 2
                            : constraints.maxWidth;
                        return Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: _MenuCard(
                                icon: Icons.add_circle_outline,
                                title: '卓を作成',
                                description: '新しい卓を作って、対局を始めます',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const CreateTablePage(),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _MenuCard(
                                icon: Icons.groups_outlined,
                                title: '卓に参加',
                                description: '参加コードなどを使って卓に加わります',
                                onTap: () => _showComingSoon(context, '卓への参加'),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _MenuCard(
                                icon: Icons.bar_chart,
                                title: '成績を見る',
                                description: 'これまでの対局成績を確認します',
                                onTap: () => _showComingSoon(context, '成績表示'),
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
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
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 132),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E1D7)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF0EB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: _menuGreen,
                  size: 26,
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
                        color: _menuInk,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
