import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';
import '../domain/app_session.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await AuthRepository().login(_emailCtrl.text.trim(), _pwCtrl.text);
      if (res['twoFactorRequired'] == true) {
        if (!mounted) return;
        context.go('/2fa?challengeId=${res['challengeId']}&userId=${res['userId']}&userName=${res['userName']}&email=${res['email']}&role=${res['role']}');
        return;
      }
      await AppSession.save(
        token: res['token'], userId: res['userId'],
        name: res['userName'], email: res['email'], role: res['role'] ?? 'USER',
      );
      if (!mounted) return;
      context.go(AppSession.isAdmin ? '/admin' : '/companies');
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.candlestick_chart, color: Colors.white, size: 48)),
              const SizedBox(height: 24),
              const Text('株式学習アプリ', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('疑似売買で投資を学ぼう', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 40),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'メールアドレス', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pwCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'パスワード', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder()),
                onSubmitted: (_) => _login(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _login,
                  child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('ログイン'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: () => context.go('/register'), child: const Text('アカウントを作成')),
            ],
          ),
        ),
      ),
    );
  }
}
