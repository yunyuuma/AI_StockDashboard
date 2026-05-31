import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/admin_repository.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});
  @override
  State<AdminUserManagementPage> createState() => _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage> {
  final _repo = AdminRepository();
  List<dynamic> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final u = await _repo.fetchUsers();
      if (mounted) setState(() => _users = u);
    } catch (e) { if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _changeRole(dynamic user) async {
    final newRole = user['role'] == 'ADMIN' ? 'USER' : 'ADMIN';
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text('${user['userName']} のロールを $newRole に変更しますか？'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('変更'))],
    ));
    if (ok != true) return;
    try {
      await _repo.updateUserRole(user['id'], newRole);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.go('/admin'), icon: const Icon(Icons.arrow_back)),
        title: const Text('ユーザー管理', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _error != null ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : ListView.separated(
              itemCount: _users.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final u = _users[i];
                final isAdmin = u['role'] == 'ADMIN';
                return ListTile(
                  leading: CircleAvatar(backgroundColor: isAdmin ? const Color(0xFF2563EB) : Colors.grey[300],
                    child: Text((u['userName'] ?? 'U')[0].toUpperCase(), style: TextStyle(color: isAdmin ? Colors.white : Colors.black))),
                  title: Text(u['userName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(u['email'] ?? ''),
                  trailing: Chip(label: Text(u['role'] ?? 'USER', style: TextStyle(color: isAdmin ? const Color(0xFF2563EB) : Colors.black54, fontSize: 12)),
                    backgroundColor: isAdmin ? const Color(0xFFEFF6FF) : Colors.grey[100]),
                  onLongPress: () => _changeRole(u),
                );
              }),
    );
  }
}
