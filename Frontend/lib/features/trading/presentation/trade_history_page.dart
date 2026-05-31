import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/trading_repository.dart';
import '../domain/trading_models.dart';

class TradeHistoryPage extends StatefulWidget {
  const TradeHistoryPage({super.key});
  @override
  State<TradeHistoryPage> createState() => _TradeHistoryPageState();
}

class _TradeHistoryPageState extends State<TradeHistoryPage> {
  final _repo = TradingRepository();
  List<TradingTrade> _trades = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final t = await _repo.fetchTrades();
      if (mounted) setState(() => _trades = t);
    } catch (e) { if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.go('/trading'), icon: const Icon(Icons.arrow_back)),
        title: const Text('売買履歴', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _error != null ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : _trades.isEmpty ? const Center(child: Text('売買履歴がありません'))
          : RefreshIndicator(onRefresh: _load, child: ListView.separated(
              itemCount: _trades.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final t = _trades[i];
                final isBuy = t.side == 'BUY';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isBuy ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    child: Icon(isBuy ? Icons.arrow_upward : Icons.arrow_downward, color: isBuy ? const Color(0xFF16A34A) : const Color(0xFFDC2626), size: 20)),
                  title: Text(t.stockName.isNotEmpty ? t.stockName : t.stockCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${isBuy ? '買い' : '売り'} ${t.quantity}株 ¥${t.price.toStringAsFixed(0)} / ${t.tradedAt.toString().length > 10 ? t.tradedAt.substring(0, 10) : t.tradedAt}'),
                  trailing: Text('¥${(t.price * t.quantity).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                );
              })),
    );
  }
}
