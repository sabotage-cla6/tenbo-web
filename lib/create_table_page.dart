import 'package:flutter/material.dart';

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
  final _passcode = TextEditingController();
  final _uma = List.generate(4, (i) => TextEditingController(text: ['30', '10', '-10', '-30'][i]));
  final _stack = TextEditingController(text: '300');
  final _tobi = TextEditingController(text: '10');
  final _yakitori = TextEditingController(text: '10');
  final _cut = TextEditingController(text: '5');
  final _in = TextEditingController(text: '6');
  String _players = '4', _start = '25000', _return = '30000';
  String _umaType = '10-30', _multiRon = 'head-bump', _rounding = 'round';
  bool _belowZero = true, _showPasscode = false;

  @override
  void dispose() {
    for (final c in [_name, _passcode, _stack, _tobi, _yakitori, _cut, _in, ..._uma]) { c.dispose(); }
    super.dispose();
  }

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _setUma(String? value) {
    if (value == null) return;
    const presets = <String, List<String>>{
      '10-30': ['30', '10', '-10', '-30'],
      '10-20': ['20', '10', '-10', '-20'],
      '5-10': ['10', '5', '-5', '-10'],
      'none': ['0', '0', '0', '0'],
    };
    setState(() {
      _umaType = value;
      final values = presets[value];
      if (values != null) {
        for (var i = 0; i < 4; i++) { _uma[i].text = values[i]; }
      }
    });
  }

  void _setCut(String value) {
    final n = int.tryParse(value);
    setState(() {
      if (value.isEmpty) { _in.clear(); }
      else if (n != null && n >= 0 && n <= 8) { _in.text = '${n + 1}'; }
    });
  }

  void _create() {
    if (_name.text.trim().isEmpty) {
      _message('卓の名称を入力してください。');
    } else if (_passcode.text.isNotEmpty && !RegExp(r'^\d{4}$').hasMatch(_passcode.text)) {
      _message('パスコードは半角数字4桁で入力してください。');
    } else {
      _message('卓の作成・設定保存機能は今後実装します。現在、設定内容は保存されません。');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: _paper, foregroundColor: _ink, titleSpacing: 24,
      leading: IconButton(tooltip: 'ホームに戻る', onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_back)),
      title: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.sports_esports, color: _gold, size: 26), SizedBox(width: 10),
        Text('天棒', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3)),
      ]),
    ),
    body: Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [_paper, Color(0xFFECEFE9)],
      )),
      child: SafeArea(top: false, child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('新規卓の作成', textAlign: TextAlign.center,
              style: TextStyle(color: _ink, fontSize: 25, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('対局ルールを設定して、新しい卓を準備します。',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 24),
            _Section(title: '基本情報設定', icon: Icons.edit_note, children: [
              _TextRow(title: '卓の名称', description: '参加者に表示される名前',
                controller: _name, hint: '例：たなか卓', maxLength: 40, align: TextAlign.left),
              _TextRow(title: 'パスコード', description: '入室用・任意の半角数字4桁',
                controller: _passcode, hint: '設定しない場合は空欄', maxLength: 4,
                keyboard: TextInputType.number, obscure: !_showPasscode,
                suffix: IconButton(tooltip: _showPasscode ? '隠す' : '表示',
                  onPressed: () => setState(() => _showPasscode = !_showPasscode),
                  icon: Icon(_showPasscode ? Icons.visibility_off : Icons.visibility))),
            ]),
            const SizedBox(height: 14),
            _Section(title: '既存卓情報コピー', icon: Icons.content_copy, children: [
              SizedBox(width: double.infinity, child: OutlinedButton.icon(
                onPressed: () => _message('保存済みの卓がないため、設定コピー機能は今後実装します。'),
                icon: const Icon(Icons.file_download_outlined), label: const Text('既存の卓から設定を読み込む'),
                style: OutlinedButton.styleFrom(foregroundColor: _green,
                  side: const BorderSide(color: Color(0xFFB9C9BE)),
                  padding: const EdgeInsets.symmetric(vertical: 14)))),
            ]),
            const SizedBox(height: 14),
            _Section(title: '対局形式', icon: Icons.grid_view_rounded, children: [
              _RowSetting(title: '人数設定', control: SegmentedButton<String>(
                segments: const [ButtonSegment(value: '4', label: Text('四人麻雀')), ButtonSegment(value: '3', label: Text('三人麻雀'))],
                selected: {_players}, onSelectionChanged: (v) => setState(() => _players = v.first),
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact,
                  textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12))))),
              _SelectRow(title: '配給原点', value: _start,
                options: const {'25000':'25,000点','26000':'26,000点','30000':'30,000点','35000':'35,000点'},
                onChanged: (v) => setState(() => _start = v)),
              _SelectRow(title: '返し点', value: _return,
                options: const {'30000':'30,000点','25000':'25,000点','40000':'40,000点'},
                onChanged: (v) => setState(() => _return = v)),
              _SelectRow(title: 'ウマ', value: _umaType,
                options: const {'10-30':'10 - 30','10-20':'10 - 20','5-10':'5 - 10','none':'なし','custom':'その他'},
                onChanged: _setUma),
              if (_umaType == 'custom') _CustomBox(title: '着順ごとのウマ（pt）',
                child: Row(children: List.generate(_players == '4' ? 4 : 3, (i) =>
                  Expanded(child: Padding(padding: EdgeInsets.only(right: i == 3 ? 0 : 8),
                    child: Column(children: [
                      Text('${i + 1}着', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 6),
                      TextField(controller: _uma[i],
                        keyboardType: const TextInputType.numberWithOptions(signed: true),
                        textAlign: TextAlign.center, decoration: _input()),
                    ])))))),
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
                  'ceil':'切り上げ','floor':'切り捨て','custom':'その他',
                }, onChanged: (v) => setState(() => _rounding = v)),
              if (_rounding == 'custom') _CustomBox(title: '端数処理の境界値',
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: 76, child: TextField(controller: _cut,
                    keyboardType: TextInputType.number, textAlign: TextAlign.center,
                    onChanged: _setCut, decoration: _input())),
                  const SizedBox(width: 8), const Text('捨'), const SizedBox(width: 20),
                  SizedBox(width: 76, child: TextField(controller: _in,
                    enabled: false, textAlign: TextAlign.center, decoration: _input())),
                  const SizedBox(width: 8), const Text('入'),
                ])),
            ]),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (context, c) {
              final home = OutlinedButton.icon(onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.home_outlined), label: const Text('ホーム'), style: _secondaryStyle());
              final create = FilledButton.icon(onPressed: _create,
                icon: const Icon(Icons.add_circle_outline), label: const Text('卓を作成して部屋に入る'), style: _primaryStyle());
              return c.maxWidth < 420
                ? Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [home, const SizedBox(height: 10), create])
                : Row(children: [Expanded(child: home), const SizedBox(width: 12), Expanded(flex: 2, child: create)]);
            }),
            const SizedBox(height: 14),
            const Text('※ 現在は設定画面の試作段階です。卓の作成・設定保存はまだ行われません。',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.black45, fontSize: 11)),
          ]),
        ),
      ))),
    ),
  );
}

ButtonStyle _primaryStyle() => FilledButton.styleFrom(
  backgroundColor: _green, foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
  textStyle: const TextStyle(fontWeight: FontWeight.bold),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)));
ButtonStyle _secondaryStyle() => OutlinedButton.styleFrom(
  foregroundColor: _ink, side: const BorderSide(color: Color(0xFFB9C9BE)),
  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
  textStyle: const TextStyle(fontWeight: FontWeight.bold),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)));
InputDecoration _input() => InputDecoration(
  isDense: true, filled: true, fillColor: _paper,
  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: Color(0xFFE0E5DD))),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: Color(0xFFE0E5DD))),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: _green, width: 1.5)));

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.children});
  final String title; final IconData icon; final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white, elevation: 0, clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFE5E1D7))),
    child: ExpansionTile(initiallyExpanded: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      iconColor: _green, collapsedIconColor: Colors.black45,
      title: Row(children: [
        Icon(icon, color: _green, size: 20), const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.bold)),
      ]),
      children: [
        const Divider(height: 1, color: Color(0xFFECEFE9)), const SizedBox(height: 12),
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) const Divider(height: 20, color: Color(0xFFF0F0EB)),
        ],
      ],
    ),
  );
}

class _RowSetting extends StatelessWidget {
  const _RowSetting({required this.title, required this.control, this.description});
  final String title; final String? description; final Widget control;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
    final label = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.bold)),
      if (description != null) ...[
        const SizedBox(height: 3), Text(description!, style: const TextStyle(color: Colors.black54, fontSize: 11)),
      ],
    ]);
    if (c.maxWidth < 430) return Column(crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [label, const SizedBox(height: 8), Align(alignment: Alignment.centerRight, child: control)]);
    return Row(children: [Expanded(child: label), const SizedBox(width: 12),
      ConstrainedBox(constraints: const BoxConstraints(maxWidth: 260, minWidth: 150), child: control)]);
  });
}

class _SelectRow extends StatelessWidget {
  const _SelectRow({required this.title, required this.value, required this.options,
    required this.onChanged, this.description});
  final String title; final String? description; final String value;
  final Map<String, String> options; final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => _RowSetting(title: title, description: description,
    control: DropdownButtonFormField<String>(
      initialValue: value, isExpanded: true,
      decoration: InputDecoration(isDense: true, filled: true, fillColor: _paper,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E5DD))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E5DD)))),
      items: options.entries.map((e) => DropdownMenuItem(value: e.key,
        child: Text(e.value, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))).toList(),
      onChanged: (v) { if (v != null) {
          onChanged(v);
        } },
    ));
}

class _TextRow extends StatelessWidget {
  const _TextRow({required this.title, required this.controller, required this.hint,
    this.description, this.align = TextAlign.right, this.keyboard, this.maxLength,
    this.obscure = false, this.suffix});
  final String title; final String? description; final TextEditingController controller;
  final String hint; final TextAlign align; final TextInputType? keyboard;
  final int? maxLength; final bool obscure; final Widget? suffix;
  @override
  Widget build(BuildContext context) => _RowSetting(title: title, description: description,
    control: TextField(controller: controller, textAlign: align, keyboardType: keyboard,
      maxLength: maxLength, obscureText: obscure,
      decoration: InputDecoration(hintText: hint, counterText: '', isDense: true,
        filled: true, fillColor: _paper,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E5DD))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E5DD))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _green, width: 1.5)))));
}

class _NumberRow extends StatelessWidget {
  const _NumberRow({required this.title, required this.controller, this.description, this.unit});
  final String title; final String? description; final TextEditingController controller; final String? unit;
  @override
  Widget build(BuildContext context) => _RowSetting(title: title, description: description,
    control: TextField(controller: controller,
      keyboardType: const TextInputType.numberWithOptions(signed: true), textAlign: TextAlign.right,
      decoration: InputDecoration(isDense: true, filled: true, fillColor: _paper,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), suffixText: unit,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E5DD))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E5DD))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _green, width: 1.5)))));
}

class _CustomBox extends StatelessWidget {
  const _CustomBox({required this.title, required this.child});
  final String title; final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: _paper, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E1D7))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12), child,
    ]),
  );
}
