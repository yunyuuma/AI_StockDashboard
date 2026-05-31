import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../trading/data/trading_repository.dart';
import '../../trading/domain/trading_models.dart';

class AiAdvisorHomePage extends StatefulWidget {
  const AiAdvisorHomePage({super.key});
  @override
  State<AiAdvisorHomePage> createState() => _AiAdvisorHomePageState();
}

class _AiAdvisorHomePageState extends State<AiAdvisorHomePage> {
  final _repo = TradingRepository();
  List<TradingPosition> _positions = [];
  final _codeCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _loadPositions(); }

  Future<void> _loadPositions() async {
    try {
      final p = await _repo.fetchPositions();
      if (mounted) setState(() => _positions = p);
    } catch (_) {}
  }

  Widget _menuCard(IconData icon, String title, String desc, VoidCallback onTap) => Card(
    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
        CircleAvatar(radius: 26, backgroundColor: const Color(0xFFEFF6FF), child: Icon(icon, color: const Color(0xFF2563EB))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ])),
        const Icon(Icons.chevron_right, color: Colors.black45),
      ]))),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.go('/mypage'), icon: const Icon(Icons.arrow_back)),
        title: const Text('AIアドバイザー', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
      ),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        _menuCard(Icons.pie_chart_outline, 'ポートフォリオ分析', 'リスク評価・運用アドバイス', () => context.go('/ai-advisor/portfolio')),
        const SizedBox(height: 12),
        _menuCard(Icons.history_edu_outlined, '売買レビュー', '過去の売買傾向の分析・改善提案', () => context.go('/ai-advisor/review')),
        const SizedBox(height: 12),
        _menuCard(Icons.chat_bubble_outline, 'AIチャット', 'Ollama AIに自由に質問する', () => context.go('/ai-advisor/chat')),
        const SizedBox(height: 24),
        if (_positions.isNotEmpty) ...[
          const Text('保有銘柄 AI分析', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ..._positions.map((p) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Card(
            elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(p.stockCode, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
              title: Text(p.stockName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${p.quantity}株 / 損益: ${p.profitLoss >= 0 ? '+' : ''}¥${p.profitLoss.toStringAsFixed(0)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/ai-advisor/stock/${p.stockCode}'),
            )))),
        ],
        const SizedBox(height: 16),
        Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('銘柄コード指定で分析', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: _codeCtrl, decoration: const InputDecoration(hintText: '例: 7203', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)))),
              const SizedBox(width: 10),
              FilledButton(onPressed: () { final c = _codeCtrl.text.trim(); if (c.isNotEmpty) context.go('/ai-advisor/stock/$c'); }, child: const Text('分析')),
            ]),
          ]))),
        const SizedBox(height: 20),
      ]),
    );
  }
}
