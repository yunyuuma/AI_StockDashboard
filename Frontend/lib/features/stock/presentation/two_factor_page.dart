import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/auth_repository.dart';
import '../domain/app_session.dart';

class TwoFactorPage extends StatefulWidget {
  final String challengeId, userId, userName, email, role;
  const TwoFactorPage({super.key, required this.challengeId, required this.userId,
    required this.userName, required this.email, required this.role});
  @override
  State<TwoFactorPage> createState() => _TwoFactorPageState();
}

class _TwoFactorPageState extends State<TwoFactorPage> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _verify() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await AuthRepository().verifyTwoFactor(widget.challengeId, _codeCtrl.text.trim());
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

  Future<void> _resend() async {
    try {
      await AuthRepository().resendTwoFactor(widget.challengeId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('認証コードを再送しました。')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(title: const Text('二要素認証'), backgroundColor: Colors.white, foregroundColor: Colors.black87),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const Icon(Icons.security, size: 64, color: Color(0xFF2563EB)),
          const SizedBox(height: 16),
          Text('${widget.email} に送信した\n6桁のコードを入力してください', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 24),
          TextField(
            controller: _codeCtrl, keyboardType: TextInputType.number, maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 12),
            decoration: const InputDecoration(hintText: '000000', border: OutlineInputBorder(), counterText: ''),
            onSubmitted: (_) => _verify(),
          ),
          if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.red))],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _verify,
              child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('認証する'),
            ),
          ),
          TextButton(onPressed: _resend, child: const Text('コードを再送する')),
        ]),
      ),
    );
  }
}
