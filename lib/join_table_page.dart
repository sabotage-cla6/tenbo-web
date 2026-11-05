import 'package:flutter/material.dart';

import 'table_lobby_page.dart';
import 'table_repository.dart';

const _ink = Color(0xFF18352E);
const _green = Color(0xFF245447);
const _gold = Color(0xFFD7B56D);
const _paper = Color(0xFFF7F5EF);

class JoinTablePage extends StatefulWidget {
  const JoinTablePage({
    this.findTablesByName,
    super.key,
  });

  /// テスト時に卓検索処理を差し替えられるようにする。
  final Future<List<TableInfo>> Function(String name)? findTablesByName;

  @override
  State<JoinTablePage> createState() => _JoinTablePageState();
}

class _JoinTablePageState extends State<JoinTablePage> {
  final _name = TextEditingController();
  bool _joining = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _join() async {
    if (_joining) return;

    final name = _name.text.trim();
    if (name.isEmpty) {
      _message('卓の名称を入力してください。');
      return;
    }

    setState(() => _joining = true);
    try {
      final findTables = widget.findTablesByName ??
          TableRepository().findWaitingTablesByName;
      final tables = await findTables(name);
      if (!mounted) return;

      if (tables.isEmpty) {
        _message('参加できる卓が見つかりません。卓名を確認してください。');
        return;
      }
      if (tables.length > 1) {
        _message('同じ名称で参加可能な卓が複数あります。卓名を変更してもらうか、管理者に確認してください。');
        return;
      }

      final table = tables.single;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => TableLobbyPage(
            tableId: table.id,
            tableName: table.name,
            playerCount: table.playerCount,
            settings: table.settings,
            ownerName: table.ownerName,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _message('卓を検索できませんでした。通信状態とFirestoreの設定を確認してください。');
      debugPrint('Table search failed: $error');
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: _paper,
          foregroundColor: _ink,
          titleSpacing: 24,
          leading: IconButton(
            tooltip: 'ホームに戻る',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_esports, color: _gold, size: 26),
              SizedBox(width: 10),
              Text(
                '天棒',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
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
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '卓に参加',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _ink,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '参加する卓の名称を入力してください。',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: Color(0xFFE5E1D7)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                '卓の名称',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _name,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) => _join(),
                                decoration: InputDecoration(
                                  hintText: '例：金曜夜セット麻雀',
                                  filled: true,
                                  fillColor: _paper,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              FilledButton.icon(
                                onPressed: _joining ? null : _join,
                                icon: _joining
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.login),
                                label: Text(
                                  _joining ? '検索中...' : '卓に参加する',
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: _green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
