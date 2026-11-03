import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_page.dart';

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
                constraints: const BoxConstraints(maxWidth: 1080),
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
                      '今日も楽しく、記録を積み重ねていきましょう。',
                      style: TextStyle(color: Colors.black54, fontSize: 15),
                    ),
                    const SizedBox(height: 28),
                    _WelcomeCard(
                      onRecordTap: () => _showComingSoon(context, '対局記録'),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'メニュー',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 700 ? 3 : 1;
                        const spacing = 14.0;
                        final itemWidth = columns == 1
                            ? constraints.maxWidth
                            : (constraints.maxWidth -
                                    spacing * (columns - 1)) /
                                columns;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            SizedBox(
                              width: itemWidth,
                              child: _MenuCard(
                                icon: Icons.edit_note,
                                title: '対局を記録',
                                description: '対局結果や点数を記録します',
                                onTap: () => _showComingSoon(context, '対局記録'),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
                              child: _MenuCard(
                                icon: Icons.bar_chart,
                                title: '成績を見る',
                                description: '勝率や平均順位などを確認します',
                                onTap: () => _showComingSoon(context, '成績表示'),
                              ),
                            ),
                            SizedBox(
                              width: itemWidth,
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
                    const SizedBox(height: 30),
                    const Text(
                      '最近の対局',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 34,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE5E1D7)),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 42,
                            color: Color(0xFF9AA7A0),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '対局記録はまだありません',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            '対局を記録すると、ここに最近の対局が表示されます。',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Center(
                      child: Text(
                        'TENBO  •  麻雀の記録を、もっと楽しく。',
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

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.onRecordTap});

  final VoidCallback onRecordTap;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                'YOUR MAHJONG LOG',
                style: TextStyle(
                  color: Color(0xFFE5CB91),
                  fontSize: 11,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '一局ずつ、成長の記録を。',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '対局を記録して、自分の打ち筋や成績を振り返りましょう。',
                style: TextStyle(color: Colors.white70, height: 1.6),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRecordTap,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE0C17F),
                  foregroundColor: const Color(0xFF18352E),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  '対局を記録する',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                size: 112,
                color: Color(0x66FFFFFF),
              ),
            ],
          );
        },
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
                child: Icon(icon, color: const Color(0xFF245447), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF18352E),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
