import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({required this.firebaseReady, super.key});

  final bool firebaseReady;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _agreedToPolicies = false;
  bool _isSubmitting = false;

  static const _ink = Color(0xFF18352E);
  static const _green = Color(0xFF245447);
  static const _gold = Color(0xFFD7B56D);
  static const _paper = Color(0xFFF7F5EF);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showPolicy(String title) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('このページは準備中です。公開時に内容を掲載します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'このメールアドレスは既に登録されています。';
      case 'invalid-email':
        return 'メールアドレスの形式を確認してください。';
      case 'weak-password':
        return 'パスワードが安全ではありません。別のパスワードを設定してください。';
      case 'operation-not-allowed':
        return 'Firebase Consoleでメール/パスワード認証が有効になっていません。';
      case 'network-request-failed':
        return 'ネットワークに接続できません。通信環境を確認してください。';
      case 'too-many-requests':
        return '試行回数が多すぎます。しばらくしてから再度お試しください。';
      default:
        return 'アカウントを作成できませんでした。時間をおいて再度お試しください。';
    }
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final local = parts[0];
    final masked = local.length <= 2
        ? '${local[0]}*'
        : '${local.substring(0, 2)}${'*' * (local.length - 2)}';
    return '$masked@${parts[1]}';
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    if (!_agreedToPolicies) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('利用規約とプライバシーポリシーへの同意が必要です。')),
      );
      return;
    }
    if (!widget.firebaseReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firebaseの設定が完了していません。READMEの設定手順を確認してください。'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = credential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'User creation returned no user.',
        );
      }

      await user.updateDisplayName(_nameController.text.trim());
      await user.sendEmailVerification();

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('仮登録が完了しました'),
          content: Text(
            '${_maskEmail(_emailController.text.trim())} 宛てに確認メールを送信しました。'
            'メール内のリンクを開いて、メールアドレスの確認を完了してください。',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      _passwordController.clear();
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authErrorMessage(error))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登録処理中にエラーが発生しました。')),
      );
      debugPrint('Signup failed: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _green),
      filled: true,
      fillColor: _paper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E1D7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _green, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF102A24), Color(0xFF315F50)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  elevation: 12,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 34, 32, 30),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Icon(Icons.sports_esports, size: 38, color: _gold),
                          const SizedBox(height: 8),
                          const Text(
                            '天棒',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _ink,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'TENBO',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _green,
                              fontSize: 12,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'アカウントを作成',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _ink,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _nameController,
                            maxLength: 20,
                            textInputAction: TextInputAction.next,
                            decoration: _decoration(
                              'プレイヤー名',
                              Icons.person_outline,
                            ).copyWith(counterText: ''),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'プレイヤー名を入力してください';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: _decoration(
                              'メールアドレス',
                              Icons.mail_outline,
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';
                              if (email.isEmpty) return 'メールアドレスを入力してください';
                              if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(email)) {
                                return '有効なメールアドレスを入力してください';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: _decoration(
                              'パスワード（8文字以上）',
                              Icons.lock_outline,
                            ).copyWith(
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'パスワードを表示'
                                    : 'パスワードを隠す',
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'パスワードを入力してください';
                              }
                              if (value.length < 8) return '8文字以上で入力してください';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _agreedToPolicies,
                                activeColor: _green,
                                onChanged: (value) => setState(
                                  () => _agreedToPolicies = value ?? false,
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      InkWell(
                                        onTap: () => _showPolicy('利用規約'),
                                        child: const Text(
                                          '利用規約',
                                          style: TextStyle(
                                            color: _green,
                                            decoration:
                                                TextDecoration.underline,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const Text(' と '),
                                      InkWell(
                                        onTap: () =>
                                            _showPolicy('プライバシーポリシー'),
                                        child: const Text(
                                          'プライバシーポリシー',
                                          style: TextStyle(
                                            color: _green,
                                            decoration:
                                                TextDecoration.underline,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const Text(' に同意する'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: _green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'アカウントを作成',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            widget.firebaseReady
                                ? '登録後、入力したメールアドレスに確認メールを送信します。'
                                : 'Firebase未設定のため、現在はアカウント登録できません。設定手順はREADMEを確認してください。',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
