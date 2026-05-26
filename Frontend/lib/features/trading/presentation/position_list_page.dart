import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/trading_repository.dart';
import '../domain/trading_models.dart';

class PositionListPage extends StatefulWidget {
  const PositionListPage({super.key});
  @override
  State<PositionListPage> createState() => _PositionListPageState();
}

class _PositionListPageState extends State<PositionListPage> {
  final _repo = TradingRepository();
  List<TradingPosition> _positions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final p = await _repo.fetchPositions();
      if (mounted) setState(() { _positions = p; });
    } catch (e) { if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Color _plColor(double v) => v >= 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.go('/trading'), icon: const Icon(Icons.arrow_back)),
        title: const Text('保有銘柄', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _error != null ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : _positions.isEmpty ? const Center(child: Text('保有銘柄がありません'))
          : RefreshIndicator(onRefresh: _load, child: ListView.separated(
              itemCount: _positions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = _positions[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                    child: Center(child: Text(p.stockCode, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
                  title: Text(p.stockName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${p.quantity}株 / 平均¥${p.averagePrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
                    Text('評価額: ¥${p.valuationAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
                  ]),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${p.profitLoss >= 0 ? '+' : ''}¥${p.profitLoss.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: _plColor(p.profitLoss))),
                    Text('${p.profitLossRate >= 0 ? '+' : ''}${p.profitLossRate.toStringAsFixed(2)}%', style: TextStyle(fontSize: 12, color: _plColor(p.profitLoss))),
                  ]),
                );
              })),
    );
  }
}
