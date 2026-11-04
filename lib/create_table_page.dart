import 'package:flutter/material.dart';

import 'table_repository.dart';

const _ink = Color(0xFF18352E);
const _green = Color(0xFF245447);
const _gold = Color(0xFFD7B56D);
const _paper = Color(0xFFF7F5EF);

class CreateTablePage extends StatefulWidget {
  const CreateTablePage({super.key});

  @override
  State<CreateTablePage> createState() => _CreateTablePageState();
}

class _CreateTablePageState extends State<CreateTablePage> {
  final _name = TextEditingController(text: '金曜夜セット麻雀');
  final _stack = TextEditingController(text: '300');
  final _tobi = TextEditingController(text: '10');
  final _yakitori = TextEditingController(text: '10');
  final _uma = <TextEditingController>[
    TextEditingController(text: '30'),
    TextEditingController(text: '10'),
    TextEditingController(text: '-10'),
    TextEditingController(text: '-30'),
  ];
  String _players = '4';
  String _start = '25000';
  String _return = '30000';
  String _umaType = '10-30';
  String _multiRon = 'head-bump';
  String _rounding = 'round';
  bool _belowZero = true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _stack.dispose();
    _tobi.dispose();
    _yakitori.dispose();
    for (final controller in _uma) {
      controller.dispose();
    }
    super.dispose();
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int? _number(TextEditingController controller) =>
      int.tryParse(controller.text.trim());

  Future<void> _create() async {
    if (_saving) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      _message('卓の名称を入力してください。');
      return;
    }

    final stack = _number(_stack);
    final tobi = _number(_tobi);
    final yakitori = _number(_yakitori);
    final uma = _uma.take(_players == '4' ? 4 : 3).map(_number).toList();
    if (stack == null || tobi == null || yakitori == null ||
        uma.any((value) => value == null)) {
      _message('点数の項目には半角数字を入力してください。');
      return;
    }

    setState(() => _saving = true);
    try {
      final tableId = await TableRepository().createTable(
        name: name,
        playerCount: int.parse(_players),
        settings: {
          'startingPoints': int.parse(_start),
          'returnPoints': int.parse(_return),
          'umaType': _umaType,
          'uma': uma.cast<int>(),
          'honbaPoints': stack,
          'multiRon': _multiRon,
          'belowZero': _belowZero,
          'tobiPoints': tobi,
          'yakitoriPoints': yakitori,
          'rounding': _rounding,
        },
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('卓を登録しました'),
          content: SelectableText(
            '「$name」を登録しました。\n\n卓ID：$tableId',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('ホームに戻る'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _message('卓を登録できませんでした。Firestoreの設定と通信状態を確認してください。');
      debugPrint('Table creation failed: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
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
      title: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.sports_esports, color: _gold, size: 26),
        SizedBox(width: 10),
        Text('天棒', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3)),
      ]),
    ),
    body: Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_paper, Color(0xFFECEFE9)],
      )),
      child: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('新規卓の作成', textAlign: TextAlign.center,
                    style: TextStyle(color: _ink, fontSize: 25, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('対局ルールを設定して、新しい卓を登録します。',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 24),
                  _Section(title: '基本情報設定', icon: Icons.edit_note, children: [
                    _TextRow(title: '卓の名称', description: '参加者に表示される名前',
                      controller: _name, hint: '例：たなか卓'),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('入室制限', style: TextStyle(color: _ink, fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('パスコードによる入室制限は、後続の機能追加で対応します。'),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  _Section(title: '対局形式', icon: Icons.grid_view_rounded, children: [
                    _RowSetting(title: '人数設定', control: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: '4', label: Text('四人麻雀')),
                        ButtonSegment(value: '3', label: Text('三人麻雀')),
                      ],
                      selected: {_players},
                      onSelectionChanged: (value) => setState(() => _players = value.first),
                      showSelectedIcon: false,
                    )),
                    _SelectRow(title: '配給原点', value: _start,
                      options: const {'25000':'25,000点','26000':'26,000点','30000':'30,000点','35000':'35,000点'},
                      onChanged: (v) => setState(() => _start = v)),
                    _SelectRow(title: '返し点', value: _return,
                      options: const {'30000':'30,000点','25000':'25,000点','40000':'40,000点'},
                      onChanged: (v) => setState(() => _return = v)),
                    _SelectRow(title: 'ウマ', value: _umaType,
                      options: const {'10-30':'10 - 30','10-20':'10 - 20','5-10':'5 - 10','none':'なし','custom':'その他'},
                      onChanged: (v) => setState(() {
                        _umaType = v;
                        const presets = {
                          '10-30': [30, 10, -10, -30],
                          '10-20': [20, 10, -10, -20],
                          '5-10': [10, 5, -5, -10],
                          'none': [0, 0, 0, 0],
                        };
                        final values = presets[v];
                        if (values != null) {
                          for (var i = 0; i < 4; i++) {
                            _uma[i].text = values[i].toString();
                          }
                        }
                      })),
                    if (_umaType == 'custom')
                      _CustomUma(controllers: _uma, count: _players == '4' ? 4 : 3),
                  ]),
                  const SizedBox(height: 14),
                  _Section(title: '積み棒設定', icon: Icons.stacked_bar_chart, children: [
                    _NumberRow(title: '点数', description: '1本あたりの加算点', controller: _stack, unit: '点'),
                    _SelectRow(title: '複数ロン時', description: 'ダブロン等の積み棒分配',
                      value: _multiRon, options: const {'head-bump':'頭ハネ','all':'全員'},
                      onChanged: (v) => setState(() => _multiRon = v)),
                  ]),
                  const SizedBox(height: 14),
                  _Section(title: '精算設定', icon: Icons.calculate_outlined, children: [
                    _RowSetting(title: '箱下精算', description: 'マイナス分も精算に反映',
                      control: Switch.adaptive(value: _belowZero, activeThumbColor: _green,
                        onChanged: (v) => setState(() => _belowZero = v))),
                    _NumberRow(title: '飛び賞', controller: _tobi, unit: 'pt'),
                    _NumberRow(title: '焼き鳥', controller: _yakitori, unit: 'pt'),
                    _SelectRow(title: '端数処理', description: 'ポイント計算時の丸め方式',
                      value: _rounding, options: const {
                        'round':'四捨五入','5cut6in':'五捨六入','none':'丸めなし（小数あり）',
                        'ceil':'切り上げ','floor':'切り捨て',
                      }, onChanged: (v) => setState(() => _rounding = v)),
                  ]),
                  const SizedBox(height: 24),
                  LayoutBuilder(builder: (context, constraints) {
                    final home = OutlinedButton.icon(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.home_outlined), label: const Text('ホーム'),
                    );
                    final create = FilledButton.icon(
                      onPressed: _saving ? null : _create,
                      icon: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.add_circle_outline),
                      label: Text(_saving ? '登録中...' : '卓を登録する'),
                      style: FilledButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    );
                    if (constraints.maxWidth < 420) {
                      return Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [home, const SizedBox(height: 10), create]);
                    }
                    return Row(children: [Expanded(child: home), const SizedBox(width: 12), Expanded(flex: 2, child: create)]);
                  }),
                  const SizedBox(height: 12),
                  const Text('登録した卓はFirestoreに保存されます。卓への参加・対局開始機能は今後追加します。',
                    textAlign: TextAlign.center, style: TextStyle(color: Colors.black45, fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white, elevation: 0, clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFE5E1D7))),
    child: ExpansionTile(
      initiallyExpanded: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      iconColor: _green, collapsedIconColor: Colors.black45,
      title: Row(children: [
        Icon(icon, color: _green, size: 20), const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.bold)),
      ]),
      children: [
        const Divider(height: 1, color: Color(0xFFECEFE9)),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
}

class _RowSetting extends StatelessWidget {
  const _RowSetting({required this.title, required this.control, this.description});
  final String title;
  final String? description;
  final Widget control;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final label = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.bold)),
      if (description != null)
        Text(description!, style: const TextStyle(color: Colors.black54, fontSize: 11)),
    ]);
    if (constraints.maxWidth < 430) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [label, const SizedBox(height: 8), Align(alignment: Alignment.centerRight, child: control)]);
    }
    return Row(children: [Expanded(child: label), const SizedBox(width: 12),
      ConstrainedBox(constraints: const BoxConstraints(maxWidth: 260, minWidth: 150), child: control)]);
  });
}

class _SelectRow extends StatelessWidget {
  const _SelectRow({required this.title, required this.value, required this.options,
    required this.onChanged, this.description});
  final String title;
  final String? description;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => _RowSetting(
    title: title, description: description,
    control: DropdownButtonFormField<String>(
      initialValue: value, isExpanded: true,
      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
      items: options.entries.map((entry) => DropdownMenuItem(
        value: entry.key, child: Text(entry.value, overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    ),
  );
}

class _TextRow extends StatelessWidget {
  const _TextRow({required this.title, required this.controller, required this.hint, this.description});
  final String title;
  final String? description;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) => _RowSetting(
    title: title, description: description,
    control: TextField(controller: controller, decoration: InputDecoration(
      hintText: hint, filled: true, fillColor: _paper,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    )),
  );
}

class _NumberRow extends StatelessWidget {
  const _NumberRow({required this.title, required this.controller, this.description, this.unit});
  final String title;
  final String? description;
  final TextEditingController controller;
  final String? unit;

  @override
  Widget build(BuildContext context) => _RowSetting(
    title: title, description: description,
    control: TextField(controller: controller,
      keyboardType: const TextInputType.numberWithOptions(signed: true),
      textAlign: TextAlign.right,
      decoration: InputDecoration(isDense: true, suffixText: unit, filled: true, fillColor: _paper,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
    ),
  );
}

class _CustomUma extends StatelessWidget {
  const _CustomUma({required this.controllers, required this.count});
  final List<TextEditingController> controllers;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(count, (index) => Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: index == count - 1 ? 0 : 8),
        child: Column(children: [
          Text('${index + 1}着', style: const TextStyle(fontSize: 12, color: Colors.black54)),
          TextField(controller: controllers[index],
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            textAlign: TextAlign.center, decoration: const InputDecoration(isDense: true, border: OutlineInputBorder())),
        ]),
      ),
    )),
  );
}
