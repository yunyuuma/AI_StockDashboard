import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/ai_repository.dart';
import '../domain/ai_models.dart';

class AiTradingReviewPage extends StatefulWidget {
  const AiTradingReviewPage({super.key});
  @override
  State<AiTradingReviewPage> createState() => _AiTradingReviewPageState();
}

class _AiTradingReviewPageState extends State<AiTradingReviewPage> {
  final _repo = AiRepository();
  AiTradingReviewResult? _result;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _repo.fetchTradingReview();
      if (mounted) setState(() => _result = r);
    } catch (e) { if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Widget _section(String title, List<String> items, {Color? headColor}) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: headColor)),
        const SizedBox(height: 10),
        ...items.map((s) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('・ ', style: TextStyle(color: Colors.black54)),
          Expanded(child: Text(s, style: const TextStyle(height: 1.5))),
        ]))),
      ])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.go('/ai-advisor'), icon: const Icon(Icons.arrow_back)),
        title: const Text('売買レビュー', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  const Text('売買サマリー', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _statBox('合計取引', '${_result!.totalTrades}回')),
                    const SizedBox(width: 10),
                    Expanded(child: _statBox('買い', '${_result!.buyCount}回', color: const Color(0xFFDC2626))),
                    const SizedBox(width: 10),
                    Expanded(child: _statBox('売り', '${_result!.sellCount}回', color: const Color(0xFF16A34A))),
                  ]),
                  const SizedBox(height: 14),
                  Text(_result!.summary, style: const TextStyle(height: 1.6)),
                ]))),
              const SizedBox(height: 12),
              _section('良い点', _result!.goodPoints, headColor: const Color(0xFF16A34A)),
              if (_result!.weakPoints.isNotEmpty) const SizedBox(height: 12),
              _section('改善ポイント', _result!.weakPoints, headColor: const Color(0xFFF59E0B)),
              if (_result!.suggestions.isNotEmpty) const SizedBox(height: 12),
              _section('提案', _result!.suggestions),
              if (_result!.warnings.isNotEmpty) const SizedBox(height: 12),
              _section('注意事項', _result!.warnings, headColor: const Color(0xFFDC2626)),
              const SizedBox(height: 20),
            ]),
    );
  }

  Widget _statBox(String label, String value, {Color? color}) => Container(
    padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
    ]));
}
