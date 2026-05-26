import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/admin_repository.dart';

class AdminCompanyProfileEditPage extends StatefulWidget {
  final String stockCode;
  const AdminCompanyProfileEditPage({super.key, required this.stockCode});
  @override
  State<AdminCompanyProfileEditPage> createState() => _AdminCompanyProfileEditPageState();
}

class _AdminCompanyProfileEditPageState extends State<AdminCompanyProfileEditPage> {
  final _repo = AdminRepository();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _webCtrl = TextEditingController();
  final _marketCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _mapCtrl = TextEditingController();
  final _trendsCtrl = TextEditingController();
  bool _loading = true, _saving = false;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final d = await _repo.fetchCompanyProfile(widget.stockCode);
      _nameCtrl.text = d['companyName'] ?? '';
      _descCtrl.text = d['description'] ?? '';
      _webCtrl.text = d['website'] ?? '';
      _marketCtrl.text = d['market'] ?? '';
      _industryCtrl.text = d['industry'] ?? '';
      _mapCtrl.text = d['mapQuery'] ?? '';
      _trendsCtrl.text = d['trendsKeyword'] ?? '';
    } catch (_) {}
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      await _repo.saveCompanyProfile(widget.stockCode, {
        'companyName': _nameCtrl.text.trim(), 'description': _descCtrl.text.trim(),
        'website': _webCtrl.text.trim(), 'market': _marketCtrl.text.trim(),
        'industry': _industryCtrl.text.trim(), 'mapQuery': _mapCtrl.text.trim(),
        'trendsKeyword': _trendsCtrl.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存しました。')));
      context.go('/admin/company-profiles');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(controller: ctrl, maxLines: maxLines, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.go('/admin/company-profiles'), icon: const Icon(Icons.arrow_back)),
        title: Text('${widget.stockCode} プロフィール編集', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
              _field('企業名', _nameCtrl),
              _field('説明', _descCtrl, maxLines: 4),
              _field('Webサイト URL', _webCtrl),
              _field('市場', _marketCtrl),
              _field('業種', _industryCtrl),
              _field('マップ検索ワード', _mapCtrl),
              _field('Trendsキーワード', _trendsCtrl),
              if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_error!, style: const TextStyle(color: Colors.red))),
              SizedBox(width: double.infinity, child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('保存する'),
              )),
            ])),
    );
  }
}
