import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/ai_repository.dart';
import '../domain/ai_models.dart';

class AiStockAdvisorPage extends StatefulWidget {
  final String code;
  const AiStockAdvisorPage({super.key, required this.code});
  @override
  State<AiStockAdvisorPage> createState() => _AiStockAdvisorPageState();
}

class _AiStockAdvisorPageState extends State<AiStockAdvisorPage> {
  final _repo = AiRepository();
  AiStockAdvisorResult? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _repo.fetchStockAdvice(widget.code);
      if (mounted) setState(() => _result = r);
    } catch (e) { if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Color _riskColor(String r) => switch (r) { 'HIGH' => const Color(0xFFDC2626), 'MIDDLE' => const Color(0xFFF59E0B), _ => const Color(0xFF16A34A) };

  Widget _section(String title, List<String> items, {Color? headColor}) => Card(
    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: headColor)),
      const SizedBox(height: 10),
      ...items.map((s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('・ ', style: TextStyle(color: Colors.black54)),
        Expanded(child: Text(s, style: const TextStyle(height: 1.5))),
      ]))),
    ])),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.go('/ai-advisor'), icon: const Icon(Icons.arrow_back)),
        title: Text('${widget.code} AI分析', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _error != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              const SizedBox(height: 16), ElevatedButton(onPressed: _load, child: const Text('再試行')),
            ]))
          : ListView(padding: const EdgeInsets.all(16), children: [
              Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_result!.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${_result!.market} / ${_result!.sector}', style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 12),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: _riskColor(_result!.riskLevel), borderRadius: BorderRadius.circular(20)),
                    child: Text('注意度: ${_result!.riskLevel}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 12),
                  Text(_result!.summary, style: const TextStyle(height: 1.6)),
                ]))),
              const SizedBox(height: 12),
              _section('分析', _result!.analysis),
              const SizedBox(height: 12),
              _section('確認ポイント', _result!.checkPoints),
              if (_result!.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                _section('注意事項', _result!.warnings, headColor: const Color(0xFFDC2626)),
              ],
              const SizedBox(height: 20),
            ]),
    );
  }
}
