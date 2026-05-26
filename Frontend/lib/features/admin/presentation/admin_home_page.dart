import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/admin_repository.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});
  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final _repo = AdminRepository();
  Map<String, dynamic>? _dash;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final d = await _repo.fetchDashboard();
      if (mounted) setState(() { _dash = d; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  Widget _statCard(String label, String value, IconData icon) => Card(
    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CircleAvatar(radius: 22, backgroundColor: const Color(0xFFEFF6FF), child: Icon(icon, color: const Color(0xFF2563EB))),
      const SizedBox(height: 12),
      Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
    ])));

  Widget _menu(String title, String sub, IconData icon, String route) => Card(
    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: InkWell(borderRadius: BorderRadius.circular(18), onTap: () => context.go(route),
      child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        CircleAvatar(radius: 24, backgroundColor: const Color(0xFFEFF6FF), child: Icon(icon, color: const Color(0xFF2563EB))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(sub, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ])),
        const Icon(Icons.chevron_right, color: Colors.black45),
      ]))));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.go('/mypage'), icon: const Icon(Icons.arrow_back)),
        title: const Text('管理者パネル', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(20), children: [
              if (_dash != null) ...[
                GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
                  children: [
                    _statCard('ユーザー数', '${_dash!['userCount'] ?? 0}', Icons.people_outline),
                    _statCard('銘柄数', '${_dash!['stockCount'] ?? 0}', Icons.bar_chart),
                    _statCard('企業プロフィール', '${_dash!['companyProfileCount'] ?? 0}', Icons.business_outlined),
                    _statCard('売買件数', '${_dash!['tradeCount'] ?? 0}', Icons.receipt_long_outlined),
                  ]),
                const SizedBox(height: 20),
              ],
              _menu('ユーザー管理', 'ユーザー一覧・ロール変更', Icons.manage_accounts_outlined, '/admin/users'),
              const SizedBox(height: 12),
              _menu('銘柄管理', '銘柄の追加・削除', Icons.show_chart, '/admin/stocks'),
              const SizedBox(height: 12),
              _menu('企業プロフィール管理', '企業情報の登録・編集', Icons.business_outlined, '/admin/company-profiles'),
              const SizedBox(height: 20),
            ]),
    );
  }
}
