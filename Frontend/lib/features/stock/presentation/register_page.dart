import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';
import '../domain/app_session.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _twoFa = false, _loading = false;
  String? _error;

  Future<void> _register() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await AuthRepository().register(_nameCtrl.text.trim(), _emailCtrl.text.trim(), _pwCtrl.text, _twoFa);
      await AppSession.save(
        token: res['token'], userId: res['userId'],
        name: res['userName'], email: res['email'], role: res['role'] ?? 'USER',
      );
      if (!mounted) return;
      context.go('/companies');
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(title: const Text('アカウント作成'), backgroundColor: Colors.white, foregroundColor: Colors.black87),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'ユーザー名', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'メールアドレス', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _pwCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'パスワード（8〜16文字、英数字記号2種以上）', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder())),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('二要素認証を有効にする'), subtitle: const Text('ログイン時にメールでコード確認'),
            value: _twoFa, onChanged: (v) => setState(() => _twoFa = v),
          ),
          if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _register,
              child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('登録する'),
            ),
          ),
          TextButton(onPressed: () => context.go('/login'), child: const Text('ログインに戻る')),
        ]),
      ),
    );
  }
}
