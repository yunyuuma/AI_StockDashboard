import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/user_repository.dart';
import '../domain/app_session.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _repo = UserRepository();
  final _nameCtrl = TextEditingController();
  final _curPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  bool _twoFa = false;
  bool _loading = true, _savingProfile = false, _savingPw = false, _savingTwoFa = false;
  String? _profileError, _pwError, _twoFaError;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final p = await _repo.getProfile();
      _nameCtrl.text = p['userName'] ?? '';
      setState(() { _twoFa = p['twoFactorEnabled'] == true; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _saveProfile() async {
    setState(() { _savingProfile = true; _profileError = null; });
    try {
      final res = await _repo.updateProfile(_nameCtrl.text.trim());
      await AppSession.save(
        token: AppSession.token!, userId: AppSession.userId!,
        name: res['userName'] ?? _nameCtrl.text.trim(),
        email: AppSession.email!, role: AppSession.role!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('プロフィールを更新しました。')));
    } catch (e) { setState(() => _profileError = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => _savingProfile = false); }
  }

  Future<void> _savePassword() async {
    setState(() { _savingPw = true; _pwError = null; });
    try {
      await _repo.updatePassword(_curPwCtrl.text, _newPwCtrl.text);
      _curPwCtrl.clear(); _newPwCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('パスワードを更新しました。')));
    } catch (e) { setState(() => _pwError = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => _savingPw = false); }
  }

  Future<void> _saveTwoFa(bool v) async {
    setState(() { _savingTwoFa = true; _twoFaError = null; });
    try {
      await _repo.setTwoFactor(v);
      setState(() => _twoFa = v);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('二要素認証を${v ? '有効' : '無効'}にしました。')));
    } catch (e) { setState(() => _twoFaError = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => _savingTwoFa = false); }
  }

  Widget _section(String title, List<Widget> children) => Card(
    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16), ...children,
    ])));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.go('/mypage'), icon: const Icon(Icons.arrow_back)),
        title: const Text('アカウント設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              _section('プロフィール', [
                TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'ユーザー名', border: OutlineInputBorder())),
                if (_profileError != null) ...[const SizedBox(height: 8), Text(_profileError!, style: const TextStyle(color: Colors.red))],
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: _savingProfile ? null : _saveProfile, child: _savingProfile ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('プロフィールを保存'))),
              ]),
              const SizedBox(height: 16),
              _section('パスワード変更', [
                TextField(controller: _curPwCtrl, obscureText: true, decoration: const InputDecoration(labelText: '現在のパスワード', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _newPwCtrl, obscureText: true, decoration: const InputDecoration(labelText: '新しいパスワード（8〜16文字、英数字記号2種以上）', border: OutlineInputBorder())),
                if (_pwError != null) ...[const SizedBox(height: 8), Text(_pwError!, style: const TextStyle(color: Colors.red))],
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: _savingPw ? null : _savePassword, child: _savingPw ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('パスワードを変更'))),
              ]),
              const SizedBox(height: 16),
              _section('二要素認証', [
                SwitchListTile(
                  title: const Text('二要素認証を有効にする'),
                  subtitle: const Text('ログイン時にメールでコード確認'),
                  value: _twoFa,
                  onChanged: _savingTwoFa ? null : _saveTwoFa,
                  contentPadding: EdgeInsets.zero,
                ),
                if (_twoFaError != null) Text(_twoFaError!, style: const TextStyle(color: Colors.red)),
              ]),
              const SizedBox(height: 20),
            ]),
    );
  }
}
