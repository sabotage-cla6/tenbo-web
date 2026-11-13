import 'package:flutter/material.dart';

import 'in_game_page.dart';
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
    this.seatsStream,
    this.statusStream,
    this.startGame,
    this.assignSeat,
    this.randomizeSeats,
    this.chooseDealer,
    this.currentUserUid,
    this.repository,
    super.key,
  });

  final String tableId;
  final String tableName;
  final int playerCount;
  final Map<String, dynamic> settings;
  final String ownerName;
  final Stream<List<TableMember>>? membersStream;
  final Stream<Map<String, String?>>? seatsStream;
  final Stream<String>? statusStream;
  final Future<void> Function()? startGame;
  final Future<void> Function(String wind)? assignSeat;
  final Future<void> Function()? randomizeSeats;
  final Future<void> Function()? chooseDealer;
  final String? currentUserUid;
  final TableRepository? repository;

  TableRepository get _repository => repository ?? TableRepository();

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

  Future<void> _runSeatAction(
    BuildContext context,
    Future<void> Function() action, {
    String failureMessage = '座席の更新に失敗しました。',
  }) async {
    try {
      await action();
    } catch (error) {
      if (!context.mounted) return;
      final message = error is StateError
          ? error.message.toString()
          : failureMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Widget _buildDealerButtons(
    BuildContext context,
    Map<String, String?> seats,
    int playerCount,
  ) {
    final uid = currentUserUid ?? _repository.currentUserUid;
    final canChoose = uid != null && seats.values.contains(uid);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canChoose
                    ? () => _runSeatAction(
                          context,
                          randomizeSeats ??
                              () => _repository.randomizeSeats(
                                    tableId,
                                    playerCount,
                                  ),
                        )
                    : null,
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
                onPressed: canChoose
                    ? () => _runSeatAction(
                          context,
                          chooseDealer ??
                              () => _repository.chooseDealer(
                                    tableId,
                                    playerCount,
                                  ),
                        )
                    : null,
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
        if (!canChoose)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              '起家を決めるには、先に対局者の席に入ってください。',
              style: TextStyle(color: Colors.black54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
      ],
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
                      stream: membersStream ?? _repository.watchMembers(tableId),
                      initialData: [
                        TableMember(uid: 'owner', displayName: ownerName, isOwner: true),
                      ],
                      builder: (context, memberSnapshot) {
                        final loadedMembers = memberSnapshot.data ?? const <TableMember>[];
                        final hasOwner = loadedMembers.any((member) => member.isOwner);
                        final members = hasOwner
                            ? loadedMembers
                            : [
                                TableMember(uid: 'owner', displayName: ownerName, isOwner: true),
                                ...loadedMembers,
                              ];
                        final memberByUid = {for (final member in members) member.uid: member};
                        return _LobbyCard(
                          title: '参加者・対局中プレイヤー',
                          icon: Icons.groups_outlined,
                          trailing: Text(
                            '参加者 ${members.length}人',
                            style: const TextStyle(
                              color: _green,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('参加者',
                                  style: TextStyle(color: _ink, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              if (memberSnapshot.hasError)
                                const Text('参加者情報を取得できませんでした。',
                                    style: TextStyle(color: Colors.red)),
                              for (final member in members)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 5),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 18, color: Colors.black45),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(member.displayName,
                                            style: const TextStyle(color: _ink, fontSize: 14)),
                                      ),
                                      if (member.isOwner)
                                        const Text('オーナー',
                                            style: TextStyle(color: _green, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 16),
                              const Divider(height: 1, color: Color(0xFFECEFE9)),
                              const SizedBox(height: 14),
                              const Text('対局中プレイヤー',
                                  style: TextStyle(color: _ink, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              StreamBuilder<Map<String, String?>>(
                                stream: seatsStream ?? _repository.watchSeats(tableId),
                                initialData: const {'東': null, '南': null, '西': null, '北': null},
                                builder: (context, seatSnapshot) {
                                  final seats = seatSnapshot.data ?? const <String, String?>{};
                                  return Column(
                                    children: [
                                      for (final wind in _winds.take(safePlayerCount))
                                        Padding(
                                          padding: EdgeInsets.only(
                                            bottom: wind == _winds[safePlayerCount - 1] ? 0 : 8,
                                          ),
                                          child: _PlayerSeat(
                                            wind: wind,
                                            playerName: memberByUid[seats[wind]]?.displayName,
                                            isOwner: memberByUid[seats[wind]]?.isOwner ?? false,
                                            isMine: seats[wind] == (currentUserUid ?? _repository.currentUserUid),
                                            onTap: () async {
                                              try {
                                                final assign = assignSeat ??
                                                    (seat) => _repository.assignSeat(tableId, seat);
                                                await assign(wind);
                                              } catch (error) {
                                                if (!context.mounted) return;
                                                final message = error is StateError
                                                    ? error.message.toString()
                                                    : '座席の変更に失敗しました。';
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(message)),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      const SizedBox(height: 14),
                                      _buildDealerButtons(context, seats, safePlayerCount),
                                      const SizedBox(height: 18),
                                      Builder(
                                        builder: (context) {
                                          final seatedPlayers = <String, String?>{
                                            for (final wind in _winds.take(safePlayerCount))
                                              wind: memberByUid[seats[wind]]?.displayName,
                                          };
                                          final allSeatsFilled = seatedPlayers.values.every(
                                            (name) => name != null && name.trim().isNotEmpty,
                                          );
                                          final startingPoints =
                                              (settings['startingPoints'] as num?)?.toInt() ??
                                                  25000;
                                          final gamePlayers = [
                                            for (final wind in _winds.take(safePlayerCount))
                                              GamePlayer(
                                                uid: seats[wind],
                                                wind: wind,
                                                name: seatedPlayers[wind] ?? '参加者',
                                                score: startingPoints,
                                                isDealer: wind == '東',
                                              ),
                                          ];
                                          return StreamBuilder<String>(
                                            stream: statusStream ??
                                                _repository.watchStatus(tableId),
                                            initialData: 'waiting',
                                            builder: (context, statusSnapshot) {
                                              final isWaiting =
                                                  (statusSnapshot.data ?? 'waiting') == 'waiting';
                                              return _GameStatusRedirect(
                                                isPlaying: statusSnapshot.data == 'playing' && allSeatsFilled,
                                                tableName: tableName,
                                                players: gamePlayers,
                                                startingPoints: startingPoints,
                                                tableId: tableId,
                                                currentUserUid: currentUserUid ?? _repository.currentUserUid,
                                                repository: _repository,
                                                child: FilledButton.icon(
                                                  onPressed: allSeatsFilled && isWaiting
                                                      ? () => _runSeatAction(
                                                            context,
                                                            startGame ??
                                                                () => _repository.startGame(tableId),
                                                            failureMessage: '対局の開始に失敗しました。',
                                                          )
                                                      : null,
                                                  icon: const Icon(Icons.play_arrow),
                                                  label: Text(
                                                    allSeatsFilled
                                                        ? '対局を開始する'
                                                        : '参加者が揃うと対局を開始できます',
                                                  ),
                                                  style: FilledButton.styleFrom(
                                                    backgroundColor: _green,
                                                    foregroundColor: Colors.white,
                                                    disabledBackgroundColor:
                                                        const Color(0xFFB7C3BC),
                                                    disabledForegroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F5EF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 17, color: Colors.black45),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '空席または交代したい席をクリックすると、自分がその席の対局者になります。',
                                        style: TextStyle(color: Colors.black54, fontSize: 12),
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
    required this.isMine,
    required this.onTap,
  });

  final String wind;
  final String? playerName;
  final bool isOwner;
  final bool isMine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final occupied = playerName != null && playerName!.trim().isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: occupied ? const Color(0xFFF1F5F1) : const Color(0xFFFAF9F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMine ? _gold : (occupied ? const Color(0xFFC9D9CE) : const Color(0xFFE9E5DC)),
              width: isMine ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: wind == '東' ? const Color(0xFFE9D9B5) : const Color(0xFFECEFE9),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(wind,
                    style: const TextStyle(color: _ink, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  occupied ? playerName! : '空席（クリックして参加）',
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
                  child: const Text('オーナー',
                      style: TextStyle(color: _green, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              else if (isMine)
                const Icon(Icons.check_circle, color: _green, size: 18)
              else
                const Icon(Icons.touch_app_outlined, color: Colors.black26, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}


/// Firestore上の卓状態が対局中に変わったら、この端末も対局画面へ遷移する。
class _GameStatusRedirect extends StatefulWidget {
  const _GameStatusRedirect({
    required this.isPlaying,
    required this.tableName,
    required this.players,
    required this.startingPoints,
    required this.tableId,
    required this.currentUserUid,
    required this.repository,
    required this.child,
  });

  final bool isPlaying;
  final String tableName;
  final List<GamePlayer> players;
  final int startingPoints;
  final String tableId;
  final String? currentUserUid;
  final TableRepository? repository;
  final Widget child;

  @override
  State<_GameStatusRedirect> createState() => _GameStatusRedirectState();
}

class _GameStatusRedirectState extends State<_GameStatusRedirect> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _navigateIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _GameStatusRedirect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _navigateIfNeeded();
    }
  }

  void _navigateIfNeeded() {
    if (!widget.isPlaying || _hasNavigated) return;
    _hasNavigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => InGamePage(
            tableName: widget.tableName,
            players: widget.players,
            startingPoints: widget.startingPoints,
            tableId: widget.tableId,
            currentUserUid: widget.currentUserUid,
            repository: widget.repository,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
