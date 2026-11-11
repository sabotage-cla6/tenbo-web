import 'package:flutter/material.dart';

import 'table_repository.dart';

const _ink = Color(0xFF18352E);
const _green = Color(0xFF245447);
const _gold = Color(0xFFD7B56D);
const _paper = Color(0xFFF7F5EF);

/// 卓作成後、参加者が揃うまで待機するロビー画面。
class TableLobbyPage extends StatelessWidget {
  const TableLobbyPage({
    required this.tableId,
    required this.tableName,
    required this.playerCount,
    required this.settings,
    required this.ownerName,
    this.membersStream,
    super.key,
  });

  final String tableId;
  final String tableName;
  final int playerCount;
  final Map<String, dynamic> settings;
  final String ownerName;
  final Stream<List<TableMember>>? membersStream;

  static const _winds = ['東', '南', '西', '北'];

  String _formatPoints(dynamic value) {
    if (value is! num) return '未設定';
    return value.toInt().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
  }

  String _formatUma() {
    final uma = settings['uma'];
    if (uma is List && uma.isNotEmpty) {
      return uma.map((value) => value.toString()).join(' / ');
    }
    return switch (settings['umaType']) {
      '10-30' => '30 / 10 / -10 / -30',
      '10-20' => '20 / 10 / -10 / -20',
      '5-10' => '10 / 5 / -5 / -10',
      'none' => 'なし',
      _ => '未設定',
    };
  }

  String _formatRounding() => switch (settings['rounding']) {
        'round' => '四捨五入',
        '5cut6in' => '五捨六入',
        'none' => '丸めなし',
        'ceil' => '切り上げ',
        'floor' => '切り捨て',
        _ => '未設定',
      };

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature機能は今後追加します。')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safePlayerCount = playerCount == 3 ? 3 : 4;
    final rules = [
      '${safePlayerCount}人麻雀',
      '${_formatPoints(settings['startingPoints'])}点持ち',
      '${_formatPoints(settings['returnPoints'])}点返し',
    ].join(' ・ ');
    final details = [
      'ウマ：${_formatUma()}',
      '積み棒：${_formatPoints(settings['honbaPoints'])}点',
      '箱下精算：${settings['allowNegativePoints'] == true ? 'あり' : 'なし'}',
      '端数処理：${_formatRounding()}',
    ].join('  /  ');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _paper,
        foregroundColor: _ink,
        titleSpacing: 24,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_esports, color: _gold, size: 26),
            SizedBox(width: 10),
            Text(
              '天棒',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                '対局準備ロビー',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
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
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '対局開始待ち',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6EEE8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFC9D9CE)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.hourglass_top, size: 15, color: _green),
                              SizedBox(width: 6),
                              Text(
                                '参加者募集中',
                                style: TextStyle(
                                  color: _green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '参加メンバーが揃うまで、この画面でお待ちください。',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    _LobbyCard(
                      title: '卓情報・対局ルール',
                      icon: Icons.table_restaurant_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            tableName,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Color(0xFFECEFE9)),
                          const SizedBox(height: 12),
                          Text(
                            rules,
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            details,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.key_outlined,
                                  size: 16, color: Colors.black45),
                              const SizedBox(width: 6),
                              const Text(
                                '卓ID',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SelectableText(
                                  tableId,
                                  style: const TextStyle(
                                    color: _green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    StreamBuilder<List<TableMember>>(
                      stream: membersStream ??
                          TableRepository().watchMembers(tableId),
                      initialData: [
                        TableMember(
                          uid: 'owner',
                          displayName: ownerName,
                          isOwner: true,
                        ),
                      ],
                      builder: (context, snapshot) {
                        final members = snapshot.data ?? const <TableMember>[];
                        final visibleMembers =
                            members.take(safePlayerCount).toList();
                        return _LobbyCard(
                          title: '参加プレイヤー・座席設定',
                          icon: Icons.groups_outlined,
                          trailing: Text(
                            '${members.length} / $safePlayerCount 人',
                            style: const TextStyle(
                              color: _green,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          child: Column(
                            children: [
                              if (snapshot.hasError)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    '参加者情報を取得できませんでした。',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              for (var index = 0; index < safePlayerCount; index++)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index == safePlayerCount - 1 ? 0 : 8,
                                  ),
                                  child: _PlayerSeat(
                                    wind: _winds[index],
                                    playerName: index < visibleMembers.length
                                        ? visibleMembers[index].displayName
                                        : null,
                                    isOwner: index < visibleMembers.length &&
                                        visibleMembers[index].isOwner,
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F5EF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline,
                                        size: 17, color: Colors.black45),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        members.length >= safePlayerCount
                                            ? '参加者が揃いました。'
                                            : 'あと${safePlayerCount - members.length}人の参加をお待ちください。',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showComingSoon(context, '起家・場決め'),
                            icon: const Icon(Icons.casino_outlined),
                            label: const Text('起家・場決め'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _green,
                              side: const BorderSide(color: Color(0xFFB9C9BE)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showComingSoon(context, '起家決め'),
                            icon: const Icon(Icons.sports_esports_outlined),
                            label: const Text('起家決め'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _green,
                              side: const BorderSide(color: Color(0xFFB9C9BE)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('参加者が揃うと対局を開始できます'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFB7C3BC),
                        disabledForegroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.logout),
                      label: const Text('ロビーから退出してホームに戻る'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8A514A),
                        side: const BorderSide(color: Color(0xFFD8BDB8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
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

class _LobbyCard extends StatelessWidget {
  const _LobbyCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE5E1D7)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, color: _green, size: 20),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      );
}

class _PlayerSeat extends StatelessWidget {
  const _PlayerSeat({
    required this.wind,
    required this.playerName,
    required this.isOwner,
  });

  final String wind;
  final String? playerName;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final occupied = playerName != null && playerName!.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: occupied ? const Color(0xFFF1F5F1) : const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: occupied ? const Color(0xFFC9D9CE) : const Color(0xFFE9E5DC),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: wind == '東'
                  ? const Color(0xFFE9D9B5)
                  : const Color(0xFFECEFE9),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              wind,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              occupied ? playerName! : '参加者を待っています',
              style: TextStyle(
                color: occupied ? _ink : Colors.black45,
                fontSize: 14,
                fontWeight: occupied ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isOwner && occupied)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE6EEE8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'オーナー',
                style: TextStyle(
                  color: _green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (!occupied)
            const Icon(Icons.person_add_alt_1, color: Colors.black26, size: 18),
        ],
      ),
    );
  }
}
