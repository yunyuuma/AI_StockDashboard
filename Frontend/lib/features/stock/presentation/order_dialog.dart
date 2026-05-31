import 'package:flutter/material.dart';
import '../../trading/data/trading_repository.dart';
import '../../trading/domain/trading_models.dart';

Future<OrderResult?> showOrderDialog({
  required BuildContext context,
  required String stockCode,
  required String stockName,
  required double currentPrice,
  String initialSide = 'BUY',
  String initialOrderType = 'MARKET',
  double? initialLimitPrice,
}) async {
  return showModalBottomSheet<OrderResult>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _OrderForm(
      stockCode: stockCode, stockName: stockName, currentPrice: currentPrice,
      initialSide: initialSide, initialOrderType: initialOrderType, initialLimitPrice: initialLimitPrice,
    ),
  );
}

Future<OrderResult?> showAlgoOrderDialog({
  required BuildContext context,
  required String stockCode,
  required String stockName,
  required double currentPrice,
}) async {
  return showModalBottomSheet<OrderResult>(
    context: context, isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _AlgoOrderForm(stockCode: stockCode, stockName: stockName, currentPrice: currentPrice),
  );
}

class _OrderForm extends StatefulWidget {
  final String stockCode, stockName, initialSide, initialOrderType;
  final double currentPrice;
  final double? initialLimitPrice;
  const _OrderForm({required this.stockCode, required this.stockName, required this.currentPrice,
    required this.initialSide, required this.initialOrderType, this.initialLimitPrice});
  @override
  State<_OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<_OrderForm> {
  late String _side, _type;
  final _qtyCtrl = TextEditingController(text: '100');
  late final TextEditingController _limitCtrl;
  final _stopCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  final _repo = TradingRepository();

  @override
  void initState() {
    super.initState();
    _side = widget.initialSide;
    _type = widget.initialOrderType;
    _limitCtrl = TextEditingController(text: widget.initialLimitPrice?.toStringAsFixed(0) ?? widget.currentPrice.toStringAsFixed(0));
  }

  Future<void> _submit() async {
    final qty = int.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= 0) { setState(() => _error = '数量を正しく入力してください。'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _repo.placeOrder(
        stockCode: widget.stockCode, side: _side, orderType: _type,
        quantity: qty, currentPrice: widget.currentPrice,
        limitPrice: _type == 'LIMIT' ? double.tryParse(_limitCtrl.text.trim()) : null,
        stopPrice: _type == 'STOP' ? double.tryParse(_stopCtrl.text.trim()) : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('${widget.stockName} (${widget.stockCode})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        ]),
        Text('現在価格: ¥${widget.currentPrice.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [ButtonSegment(value: 'BUY', label: Text('買い')), ButtonSegment(value: 'SELL', label: Text('売り'))],
          selected: {_side}, onSelectionChanged: (v) => setState(() => _side = v.first),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [ButtonSegment(value: 'MARKET', label: Text('成行')), ButtonSegment(value: 'LIMIT', label: Text('指値')), ButtonSegment(value: 'STOP', label: Text('逆指値'))],
          selected: {_type}, onSelectionChanged: (v) => setState(() => _type = v.first),
        ),
        const SizedBox(height: 12),
        TextField(controller: _qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '数量（株）', border: OutlineInputBorder())),
        if (_type == 'LIMIT') ...[const SizedBox(height: 12), TextField(controller: _limitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '指値価格（円）', border: OutlineInputBorder()))],
        if (_type == 'STOP') ...[const SizedBox(height: 12), TextField(controller: _stopCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '逆指値価格（円）', border: OutlineInputBorder()))],
        if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: Colors.red))],
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton(
          onPressed: _loading ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: _side == 'BUY' ? const Color(0xFF2563EB) : const Color(0xFFDC2626)),
          child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) :
            Text(_side == 'BUY' ? '買い注文を確認' : '売り注文を確認'),
        )),
        const SizedBox(height: 24),
      ])),
    );
  }
}

class _AlgoOrderForm extends StatefulWidget {
  final String stockCode, stockName;
  final double currentPrice;
  const _AlgoOrderForm({required this.stockCode, required this.stockName, required this.currentPrice});
  @override
  State<_AlgoOrderForm> createState() => _AlgoOrderFormState();
}

class _AlgoOrderFormState extends State<_AlgoOrderForm> {
  String _algoType = 'IFD';
  final _qtyCtrl = TextEditingController(text: '100');
  final _entryCtrl = TextEditingController();
  final _profitCtrl = TextEditingController();
  final _stopCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  final _repo = TradingRepository();

  @override
  void initState() {
    super.initState();
    _entryCtrl.text = widget.currentPrice.toStringAsFixed(0);
    _profitCtrl.text = (widget.currentPrice * 1.05).toStringAsFixed(0);
    _stopCtrl.text = (widget.currentPrice * 0.95).toStringAsFixed(0);
  }

  Future<void> _submit() async {
    final qty = int.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= 0) { setState(() => _error = '数量を正しく入力してください。'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _repo.placeAlgoOrder(
        stockCode: widget.stockCode, algoType: _algoType, quantity: qty,
        currentPrice: widget.currentPrice,
        entryLimitPrice: double.tryParse(_entryCtrl.text.trim()),
        profitLimitPrice: double.tryParse(_profitCtrl.text.trim()),
        stopPrice: double.tryParse(_stopCtrl.text.trim()),
      );
      if (!mounted) return;
      Navigator.of(context).pop(r);
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('アルゴ注文', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        ]),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [ButtonSegment(value: 'IFD', label: Text('IFD')), ButtonSegment(value: 'OCO', label: Text('OCO')), ButtonSegment(value: 'IFDOCO', label: Text('IFDOCO'))],
          selected: {_algoType}, onSelectionChanged: (v) => setState(() => _algoType = v.first),
        ),
        const SizedBox(height: 8),
        Text({'IFD': '購入後に利確設定', 'OCO': '利確・損切り同時設定', 'IFDOCO': '購入→利確・損切り'}[_algoType] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 12),
        TextField(controller: _qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '数量', border: OutlineInputBorder())),
        if (_algoType == 'IFD' || _algoType == 'IFDOCO') ...[const SizedBox(height: 12), TextField(controller: _entryCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '買い指値（円）', border: OutlineInputBorder()))],
        const SizedBox(height: 12),
        TextField(controller: _profitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '利確指値（円）', border: OutlineInputBorder())),
        if (_algoType == 'OCO' || _algoType == 'IFDOCO') ...[const SizedBox(height: 12), TextField(controller: _stopCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '損切逆指値（円）', border: OutlineInputBorder()))],
        if (_error != null) ...[const SizedBox(height: 8), Text(_error!, style: const TextStyle(color: Colors.red))],
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('$_algoType注文を確認'),
        )),
        const SizedBox(height: 24),
      ])),
    );
  }
}
