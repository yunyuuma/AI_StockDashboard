import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/admin_repository.dart';

class AdminCompanyProfileListPage extends StatefulWidget {
  const AdminCompanyProfileListPage({super.key});
  @override
  State<AdminCompanyProfileListPage> createState() => _AdminCompanyProfileListPageState();
}

class _AdminCompanyProfileListPageState extends State<AdminCompanyProfileListPage> {
  final _repo = AdminRepository();
  List<dynamic> _profiles = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await _repo.fetchCompanyProfiles();
      if (mounted) setState(() => _profiles = p);
    } catch (_) {}
    finally { if (mounted) setState(() => _loading = false); }
  }

  List<dynamic> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _profiles;
    return _profiles.where((p) => (p['stockCode'] ?? '').toLowerCase().contains(q) || (p['companyName'] ?? '').toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.go('/admin'), icon: const Icon(Icons.arrow_back)),
        title: const Text('企業プロフィール管理', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(controller: _searchCtrl,
          decoration: InputDecoration(hintText: '銘柄コード・企業名で検索', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(vertical: 8)),
          onChanged: (_) => setState(() {}))),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = _filtered[i];
                  return ListTile(
                    leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text(p['stockCode'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)))),
                    title: Text(p['companyName']?.isNotEmpty == true ? p['companyName'] : '（未登録）', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(p['industry'] ?? ''),
                    trailing: const Icon(Icons.edit_outlined, color: Colors.black54),
                    onTap: () => context.go('/admin/company-profiles/${p['stockCode']}'),
                  );
                })),
      ]),
    );
  }
}
