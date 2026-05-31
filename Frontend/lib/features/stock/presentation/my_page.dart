import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../domain/app_session.dart';
import '../data/user_repository.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final _repo = UserRepository();
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await _repo.getProfile();
      if (mounted) setState(() { _profile = p; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await AppSession.clear();
    if (!mounted) return;
    context.go('/login');
  }

  Widget _menuItem(IconData icon, String title, String sub, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(radius: 24, backgroundColor: const Color(0xFFEFF6FF), child: Icon(icon, color: const Color(0xFF2563EB))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(sub, style: const TextStyle(color: Colors.black54, fontSize: 13)),
            ])),
            const Icon(Icons.chevron_right, color: Colors.black45),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.go('/companies'), icon: const Icon(Icons.arrow_back)),
        title: const Text('マイページ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(20), children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(children: [
                    CircleAvatar(radius: 32, backgroundColor: const Color(0xFF2563EB), child: Text(
                      (_profile?['userName'] ?? 'U').substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_profile?['userName'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_profile?['email'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                        child: Text(_profile?['role'] ?? 'USER', style: const TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.bold))),
                    ])),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              _menuItem(Icons.show_chart, '疑似売買', '成行・指値・アルゴ注文でシミュレーション', () => context.go('/trading')),
              const SizedBox(height: 12),
              _menuItem(Icons.psychology_outlined, 'AIアドバイザー', 'ポートフォリオ分析・銘柄アドバイス', () => context.go('/ai-advisor')),
              const SizedBox(height: 12),
              if (AppSession.isAdmin) ...[
                _menuItem(Icons.admin_panel_settings_outlined, '管理者パネル', 'ユーザー・銘柄・企業情報の管理', () => context.go('/admin')),
                const SizedBox(height: 12),
              ],
              _menuItem(Icons.settings_outlined, 'アカウント設定', 'プロフィール・パスワード・2FA設定', () => context.go('/settings')),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('ログアウト', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                ),
              ),
            ]),
    );
  }
}
