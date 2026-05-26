import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/trading_repository.dart';
import '../domain/trading_models.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});
  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  final _repo = TradingRepository();
  List<TradingOrder> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final o = await _repo.fetchOrders();
      if (mounted) setState(() => _orders = o);
    } catch (e) { if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _cancel(int orderId) async {
    try {
      await _repo.cancelOrder(orderId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('注文を取消しました。')));
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Color _statusColor(String s) => switch (s) {
    'OPEN' || 'WAITING' => const Color(0xFF2563EB),
    'FILLED' => const Color(0xFF16A34A),
    'CANCELED' => Colors.grey,
    _ => Colors.black54,
  };

  String _statusLabel(String s) => switch (s) {
    'OPEN' => '受付中', 'WAITING' => '待機中', 'FILLED' => '約定済み', 'CANCELED' => '取消済み', _ => s,
  };

  String _sideLabel(String s) => s == 'BUY' ? '買い' : '売り';
  String _typeLabel(String s) => switch (s) { 'MARKET' => '成行', 'LIMIT' => '指値', 'STOP' => '逆指値', _ => s };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.go('/trading'), icon: const Icon(Icons.arrow_back)),
        title: const Text('注文一覧', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _error != null ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : _orders.isEmpty ? const Center(child: Text('注文履歴がありません'))
          : RefreshIndicator(onRefresh: _load, child: ListView.separated(
              itemCount: _orders.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final o = _orders[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Row(children: [
                    Text(o.stockName.isNotEmpty ? o.stockName : o.stockCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: _statusColor(o.status).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(_statusLabel(o.status), style: TextStyle(fontSize: 11, color: _statusColor(o.status), fontWeight: FontWeight.bold))),
                  ]),
                  subtitle: Text('${_sideLabel(o.side)} / ${_typeLabel(o.orderType)} / ${o.quantity}株${o.algoType != 'NONE' ? ' [${o.algoType}]' : ''}'),
                  trailing: (o.status == 'OPEN' || o.status == 'WAITING') ? TextButton(
                    onPressed: () => _cancel(o.orderId), child: const Text('取消', style: TextStyle(color: Colors.red))) : null,
                );
              })),
    );
  }
}
