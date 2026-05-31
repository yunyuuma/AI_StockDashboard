import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/trading_repository.dart';
import '../domain/trading_models.dart';

class TradingHomePage extends StatefulWidget {
  const TradingHomePage({super.key});
  @override
  State<TradingHomePage> createState() => _TradingHomePageState();
}

class _TradingHomePageState extends State<TradingHomePage> {
  final _repo = TradingRepository();
  TradingSummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final s = await _repo.fetchSummary();
      if (mounted) setState(() => _summary = s);
    } catch (e) { if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Widget _menu(IconData icon, String title, String desc, VoidCallback onTap) => Card(
    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
        CircleAvatar(radius: 27, backgroundColor: const Color(0xFFEFF6FF), child: Icon(icon, color: const Color(0xFF2563EB))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
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
        title: const Text('疑似売買', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _error != null ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : ListView(padding: const EdgeInsets.all(20), children: [
              Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
                  const CircleAvatar(radius: 30, backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF2563EB))),
                  const SizedBox(width: 16),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('仮想残高', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('¥${_summary!.cash.toStringAsFixed(0)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  ]),
                ]))),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.inventory_2_outlined, color: Color(0xFF2563EB)),
                    const SizedBox(height: 8),
                    Text('${_summary!.positionCount}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const Text('保有銘柄', style: TextStyle(color: Colors.black54)),
                  ])))),
                const SizedBox(width: 12),
                Expanded(child: Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.history, color: Color(0xFF2563EB)),
                    const SizedBox(height: 8),
                    Text('${_summary!.tradeCount}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const Text('売買履歴', style: TextStyle(color: Colors.black54)),
                  ])))),
              ]),
              const SizedBox(height: 14),
              _menu(Icons.receipt_long_outlined, '注文一覧', '未約定・約定済み・取消済みの注文', () => context.go('/trading/orders')),
              const SizedBox(height: 12),
              _menu(Icons.inventory_2_outlined, '保有銘柄一覧', '保有銘柄・数量・含み損益の確認', () => context.go('/trading/positions')),
              const SizedBox(height: 12),
              _menu(Icons.history, '売買履歴', '約定した売買の一覧', () => context.go('/trading/trades')),
              const SizedBox(height: 12),
              _menu(Icons.pie_chart_outline, 'ポートフォリオ', '総資産・資産推移・セクター配分', () => context.go('/trading/portfolio')),
            ]),
    );
  }
}
