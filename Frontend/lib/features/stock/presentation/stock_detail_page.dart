import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/stock_detail_repository.dart';
import '../data/stock_news_repository.dart';
import '../data/favorite_repository.dart';
import '../domain/stock_detail_models.dart';
import '../domain/app_session.dart';
import '../../trading/data/trading_repository.dart';
import '../../trading/domain/trading_models.dart';
import 'order_dialog.dart';

class StockDetailPage extends StatefulWidget {
  final String code;
  const StockDetailPage({super.key, required this.code});
  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

class _StockDetailPageState extends State<StockDetailPage> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _detailRepo = StockDetailRepository();
  final _newsRepo = StockNewsRepository();
  final _favRepo = FavoriteRepository();
  final _tradingRepo = TradingRepository();

  StockDetailSummary? _summary;
  List<StockChartPoint> _chart = [];
  StockMetrics? _metrics;
  StockCompanyInfo? _company;
  List<StockNews> _news = [];
  OrderBook? _orderBook;
  List<TradingOrder> _openOrders = [];
  bool _isFav = false;
  bool _loading = true;
  String? _error;
  String _range = '6M';
  String _chartType = 'candle';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _detailRepo.fetchSummary(widget.code),
        _detailRepo.fetchChart(widget.code),
        _detailRepo.fetchMetrics(widget.code),
        _detailRepo.fetchCompany(widget.code),
        _newsRepo.fetchNews(widget.code),
        if (AppSession.userId != null) _favRepo.fetchFavoriteCodes(AppSession.userId!),
      ]);
      final summary = results[0] as StockDetailSummary;
      setState(() {
        _summary = summary;
        _chart = results[1] as List<StockChartPoint>;
        _metrics = results[2] as StockMetrics;
        _company = results[3] as StockCompanyInfo;
        _news = results[4] as List<StockNews>;
        if (results.length > 5) _isFav = (results[5] as List<String>).contains(widget.code);
      });
      _loadOrderBook(summary);
      _loadOpenOrders();
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadOrderBook(StockDetailSummary s) async {
    if (s.price <= 0) return;
    try {
      final ob = await _tradingRepo.fetchOrderBook(stockCode: s.code, currentPrice: s.price);
      if (mounted) setState(() => _orderBook = ob);
    } catch (_) {}
  }

  Future<void> _loadOpenOrders() async {
    try {
      final orders = await _tradingRepo.fetchOpenOrders();
      if (mounted) setState(() => _openOrders = orders);
    } catch (_) {}
  }

  Future<void> _toggleFav() async {
    if (AppSession.userId == null) return;
    try {
      if (_isFav) {
        await _favRepo.deleteFavorite(AppSession.userId!, widget.code);
      } else {
        await _favRepo.addFavorite(AppSession.userId!, widget.code);
      }
      setState(() => _isFav = !_isFav);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  List<StockChartPoint> get _filteredChart {
    final total = _chart.length;
    return switch (_range) {
      '1M' => _chart.skip(math.max(0, total - 22)).toList(),
      '3M' => _chart.skip(math.max(0, total - 66)).toList(),
      '1Y' => _chart.skip(math.max(0, total - 240)).toList(),
      'ALL' => _chart,
      _ => _chart.skip(math.max(0, total - 120)).toList(),
    };
  }

  List<double?> _ma(List<StockChartPoint> pts, int w) {
    return List.generate(pts.length, (i) {
      if (i + 1 < w) return null;
      return pts.sublist(i - w + 1, i + 1).fold(0.0, (s, p) => s + p.close) / w;
    });
  }

  List<double?> _rsi14(List<StockChartPoint> pts) {
    if (pts.length < 15) return List.filled(pts.length, null);
    final result = List<double?>.filled(pts.length, null);
    for (int i = 14; i < pts.length; i++) {
      double gain = 0, loss = 0;
      for (int j = i - 13; j <= i; j++) {
        final diff = pts[j].close - pts[j - 1].close;
        if (diff > 0) gain += diff; else loss -= diff;
      }
      final avgG = gain / 14, avgL = loss / 14;
      result[i] = avgL == 0 ? 100 : 100 - (100 / (1 + avgG / avgL));
    }
    return result;
  }

  String _yen(double? v) {
    if (v == null || v == 0) return '-';
    final abs = v.abs();
    final sign = v < 0 ? '-' : '';
    if (abs >= 1e12) return '$sign${(abs / 1e12).toStringAsFixed(1)}兆円';
    if (abs >= 1e8) return '$sign${(abs / 1e8).toStringAsFixed(1)}億円';
    if (abs >= 1e4) return '$sign${(abs / 1e4).toStringAsFixed(1)}万円';
    return '$sign${abs.toStringAsFixed(0)}円';
  }

  Widget _kv(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Expanded(child: Text(l, style: const TextStyle(color: Colors.black54, fontSize: 14))),
      Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
    ]),
  );

  Widget _sectionCard(String title, Widget child) => Card(
    elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12), child,
    ])),
  );

  Widget _buildHeader() {
    final s = _summary!;
    final isPlus = s.changePct >= 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 14, offset: Offset(0, 4))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text(s.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${s.market} / ${s.industry}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ])),
          IconButton(onPressed: _toggleFav,
            icon: Icon(_isFav ? Icons.star : Icons.star_border, color: _isFav ? Colors.amber : Colors.grey)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _metricBox('現在価格', s.price > 0 ? '¥${s.price.toStringAsFixed(0)}' : '-')),
          const SizedBox(width: 12),
          Expanded(child: _metricBox('前日比', s.price > 0 ? '${isPlus ? '+' : ''}${s.changePct.toStringAsFixed(2)}%' : '-',
            color: isPlus ? const Color(0xFFDC2626) : const Color(0xFF16A34A))),
        ]),
      ]),
    );
  }

  Widget _metricBox(String title, String value, {Color? color}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color ?? Colors.black87)),
    ]),
  );

  Widget _buildSummaryTab() {
    final s = _summary!; final m = _metrics;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(12), children: [
        Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
            Expanded(child: _mini('高値', s.high > 0 ? s.high.toStringAsFixed(0) : '-')),
            Expanded(child: _mini('安値', s.low > 0 ? s.low.toStringAsFixed(0) : '-')),
            Expanded(child: _mini('始値', s.open > 0 ? s.open.toStringAsFixed(0) : '-')),
            Expanded(child: _mini('出来高', _volume(s.volume))),
          ]))),
        const SizedBox(height: 14),
        if (m != null) ...[
          _sectionCard('開示情報', Column(children: [
            _kv('開示日', m.disclosedDate.isNotEmpty ? m.disclosedDate : '-'),
            _kv('書類種別', m.typeOfDocument.isNotEmpty ? m.typeOfDocument : '-'),
            _kv('対象期末', m.currentPeriodEndDate.isNotEmpty ? m.currentPeriodEndDate : '-'),
          ])),
          const SizedBox(height: 14),
          _sectionCard('決算サマリー', Column(children: [
            _kv('売上高', _yen(m.netSales)), _kv('営業利益', _yen(m.operatingProfit)),
            _kv('純利益', _yen(m.profit)), _kv('EPS', m.earningsPerShare != null ? '${m.earningsPerShare!.toStringAsFixed(1)}円' : '-'),
          ])),
          const SizedBox(height: 14),
          _sectionCard('会社予想', Column(children: [
            _kv('売上高予想', _yen(m.forecastNetSales)), _kv('純利益予想', _yen(m.forecastProfit)),
            _kv('年間配当予想', m.annualDividendPerShareForecast != null ? '${m.annualDividendPerShareForecast!.toStringAsFixed(1)}円' : '-'),
          ])),
        ],
        const SizedBox(height: 20),
      ]),
    );
  }

  String _volume(double v) {
    if (v >= 1e8) return '${(v / 1e8).toStringAsFixed(1)}億株';
    if (v >= 1e4) return '${(v / 1e4).toStringAsFixed(0)}万株';
    return '${v.toStringAsFixed(0)}株';
  }

  Widget _mini(String l, String v) => Column(children: [
    Text(l, style: const TextStyle(fontSize: 12, color: Colors.black54)),
    const SizedBox(height: 4),
    Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
  ]);

  Widget _buildChartTab() {
    final pts = _filteredChart;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
      _sectionCard('期間', Wrap(spacing: 8, children: ['1M','3M','6M','1Y','ALL'].map((r) =>
        ChoiceChip(label: Text(r), selected: _range == r, onSelected: (_) => setState(() { _range = r; }))).toList())),
      const SizedBox(height: 12),
      _sectionCard('チャート種別', SegmentedButton<String>(
        segments: const [ButtonSegment(value: 'candle', label: Text('ローソク足')), ButtonSegment(value: 'line', label: Text('折れ線'))],
        selected: {_chartType}, onSelectionChanged: (v) => setState(() => _chartType = v.first),
      )),
      const SizedBox(height: 12),
      _sectionCard('価格チャート', SizedBox(height: 280,
        child: pts.length < 2 ? const Center(child: Text('データがありません')) :
          _chartType == 'candle' ? _candleChart(pts) : _lineChart(pts))),
      const SizedBox(height: 12),
      _sectionCard('移動平均線（MA5・MA25）', SizedBox(height: 220,
        child: pts.length < 2 ? const Center(child: Text('データがありません')) : _maChart(pts))),
      const SizedBox(height: 12),
      _sectionCard('RSI（14）', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('70以上: 買われすぎ / 30以下: 売られすぎの目安', style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 10),
        SizedBox(height: 180, child: pts.length < 15 ? const Center(child: Text('データ不足')) : _rsiChart(pts)),
      ])),
    ]);
  }

  Widget _candleChart(List<StockChartPoint> pts) {
    final minY = pts.map((p) => p.low).reduce(math.min) * 0.98;
    final maxY = pts.map((p) => p.high).reduce(math.max) * 1.02;
    final step = _titleStep(pts.length);
    return BarChart(BarChartData(
      minY: minY, maxY: maxY,
      alignment: BarChartAlignment.spaceAround,
      gridData: const FlGridData(show: true),
      borderData: FlBorderData(show: true),
      titlesData: _titles(pts, step),
      barGroups: List.generate(pts.length, (i) {
        final p = pts[i];
        final rise = p.close >= p.open;
        final color = rise ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
        return BarChartGroupData(x: i, barRods: [
          BarChartRodData(fromY: p.low, toY: p.high, width: 2, color: color, borderRadius: BorderRadius.zero),
          BarChartRodData(fromY: math.min(p.open, p.close), toY: math.max(p.open, p.close), width: 8, color: color, borderRadius: BorderRadius.circular(1)),
        ]);
      }),
    ));
  }

  Widget _lineChart(List<StockChartPoint> pts) {
    final spots = pts.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.close)).toList();
    return LineChart(LineChartData(
      gridData: const FlGridData(show: true), borderData: FlBorderData(show: true),
      titlesData: _titles(pts, _titleStep(pts.length)),
      lineBarsData: [LineChartBarData(spots: spots, isCurved: false, barWidth: 2.5, color: const Color(0xFF2563EB), dotData: const FlDotData(show: false))],
    ));
  }

  Widget _maChart(List<StockChartPoint> pts) {
    final ma5 = _ma(pts, 5); final ma25 = _ma(pts, 25);
    final close = pts.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.close)).toList();
    final m5spots = <FlSpot>[], m25spots = <FlSpot>[];
    for (int i = 0; i < pts.length; i++) {
      if (ma5[i] != null) m5spots.add(FlSpot(i.toDouble(), ma5[i]!));
      if (ma25[i] != null) m25spots.add(FlSpot(i.toDouble(), ma25[i]!));
    }
    return LineChart(LineChartData(
      gridData: const FlGridData(show: true), borderData: FlBorderData(show: true),
      titlesData: _titles(pts, _titleStep(pts.length)),
      lineBarsData: [
        LineChartBarData(spots: close, isCurved: false, barWidth: 1.5, color: const Color(0xFF94A3B8), dotData: const FlDotData(show: false)),
        LineChartBarData(spots: m5spots, isCurved: false, barWidth: 2, color: const Color(0xFFF59E0B), dotData: const FlDotData(show: false)),
        LineChartBarData(spots: m25spots, isCurved: false, barWidth: 2, color: const Color(0xFF7C3AED), dotData: const FlDotData(show: false)),
      ],
    ));
  }

  Widget _rsiChart(List<StockChartPoint> pts) {
    final rsi = _rsi14(pts);
    final spots = <FlSpot>[];
    for (int i = 0; i < rsi.length; i++) { if (rsi[i] != null) spots.add(FlSpot(i.toDouble(), rsi[i]!)); }
    return LineChart(LineChartData(
      minY: 0, maxY: 100,
      gridData: const FlGridData(show: true), borderData: FlBorderData(show: true),
      extraLinesData: ExtraLinesData(horizontalLines: [
        HorizontalLine(y: 70, color: Colors.redAccent, strokeWidth: 1, dashArray: [6, 4]),
        HorizontalLine(y: 30, color: Colors.green, strokeWidth: 1, dashArray: [6, 4]),
      ]),
      titlesData: _titles(pts, _titleStep(pts.length)),
      lineBarsData: [LineChartBarData(spots: spots, isCurved: false, barWidth: 2, color: const Color(0xFF0F766E), dotData: const FlDotData(show: false))],
    ));
  }

  int _titleStep(int n) {
    if (n <= 12) return 1; if (n <= 48) return 4; if (n <= 90) return 8; return 16;
  }

  FlTitlesData _titles(List<StockChartPoint> pts, int step) => FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44,
      getTitlesWidget: (v, _) => Text(v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}K' : v.toStringAsFixed(0), style: const TextStyle(fontSize: 10, color: Colors.black54)))),
    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: step.toDouble(),
      getTitlesWidget: (v, _) {
        final i = v.toInt();
        if (i < 0 || i >= pts.length || i % step != 0) return const SizedBox.shrink();
        final d = pts[i].date;
        return Padding(padding: const EdgeInsets.only(top: 6), child: Text(d.length >= 10 ? d.substring(5, 10) : d, style: const TextStyle(fontSize: 10, color: Colors.black54)));
      })),
  );

  Widget _buildNewsTab() {
    if (_news.isEmpty) return const Center(child: Text('ニュースはありません'));
    return ListView.separated(
      itemCount: _news.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final n = _news[i];
        return ListTile(
          contentPadding: const EdgeInsets.all(12),
          title: Text(n.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text('${n.source}  ${n.publishedAt}', style: const TextStyle(color: Colors.black54, fontSize: 12))),
          trailing: const Icon(Icons.open_in_new, color: Colors.black54),
          onTap: () async { if (n.link.isNotEmpty) await launchUrl(Uri.parse(n.link), mode: LaunchMode.externalApplication); },
        );
      },
    );
  }

  Widget _buildCompanyTab() {
    final c = _company; final s = _summary!;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
      _sectionCard('企業情報', Column(children: [
        _kv('企業名', c?.companyName.isNotEmpty == true ? c!.companyName : s.name),
        _kv('市場', c?.market.isNotEmpty == true ? c!.market : s.market),
        _kv('業種', c?.industry.isNotEmpty == true ? c!.industry : s.industry),
      ])),
      const SizedBox(height: 12),
      _sectionCard('概要', Text(c?.description.isNotEmpty == true ? c!.description : '企業概要データはまだ登録されていません。', style: const TextStyle(height: 1.6))),
      const SizedBox(height: 12),
      _sectionCard('Webサイト', InkWell(
        onTap: c?.website.isNotEmpty == true ? () => launchUrl(Uri.parse(c!.website), mode: LaunchMode.externalApplication) : null,
        child: Text(c?.website.isNotEmpty == true ? c!.website : '-', style: TextStyle(color: c?.website.isNotEmpty == true ? const Color(0xFF2563EB) : Colors.black54, decoration: c?.website.isNotEmpty == true ? TextDecoration.underline : TextDecoration.none)),
      )),
      const SizedBox(height: 12),
      _sectionCard('外部リンク', Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        FilledButton.icon(
          onPressed: () { final q = c?.mapQuery.isNotEmpty == true ? c!.mapQuery : '${s.name} 本社'; launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}'), mode: LaunchMode.externalApplication); },
          icon: const Icon(Icons.map_outlined), label: const Text('Googleマップで見る')),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () { final k = c?.trendsKeyword.isNotEmpty == true ? c!.trendsKeyword : s.name; launchUrl(Uri.parse('https://trends.google.com/trends/explore?q=${Uri.encodeComponent(k)}&geo=JP'), mode: LaunchMode.externalApplication); },
          icon: const Icon(Icons.trending_up), label: const Text('Google Trendsで見る')),
      ])),
    ]);
  }

  Widget _buildTradingTab() {
    final s = _summary;
    if (s == null) return const Center(child: CircularProgressIndicator());
    return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
      _sectionCard('売買', Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _metricBox('現在価格', s.price > 0 ? '¥${s.price.toStringAsFixed(0)}' : '-'),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: FilledButton.icon(
            onPressed: s.price > 0 ? () async {
              final r = await showOrderDialog(context: context, stockCode: s.code, stockName: s.name, currentPrice: s.price, initialSide: 'BUY');
              if (mounted && r != null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.message))); _loadOpenOrders(); }
            } : null,
            icon: const Icon(Icons.add_shopping_cart), label: const Text('買う'))),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton.icon(
            onPressed: s.price > 0 ? () async {
              final r = await showOrderDialog(context: context, stockCode: s.code, stockName: s.name, currentPrice: s.price, initialSide: 'SELL');
              if (mounted && r != null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.message))); _loadOpenOrders(); }
            } : null,
            icon: const Icon(Icons.sell_outlined), label: const Text('売る'))),
        ]),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => context.go('/ai-advisor/stock/${s.code}'),
          icon: const Icon(Icons.psychology_outlined),
          label: const Text('この銘柄をAI分析')),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: () => context.go('/ai-advisor/chat/${s.code}'),
          icon: const Icon(Icons.chat_bubble_outline),
          label: const Text('Ollamaに質問する')),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: s.price > 0 ? () async {
            final r = await showAlgoOrderDialog(context: context, stockCode: s.code, stockName: s.name, currentPrice: s.price);
            if (mounted && r != null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r.message))); _loadOpenOrders(); }
          } : null,
          icon: const Icon(Icons.auto_graph), label: const Text('アルゴ注文')),
      ])),
      const SizedBox(height: 12),
      _buildOrderBookCard(),
    ]);
  }

  Widget _buildOrderBookCard() {
    final board = _orderBook;
    return _sectionCard('板情報', board == null
        ? const Text('板情報を取得できませんでした。')
        : Column(children: [
            ...board.sellBoard.reversed.map((r) => _boardRow(r.price, r.quantity, null, 'SELL')),
            Container(margin: const EdgeInsets.symmetric(vertical: 8), padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text('現在値 ¥${board.currentPrice.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 16)))),
            ...board.buyBoard.map((r) => _boardRow(r.price, null, r.quantity, 'BUY')),
          ]));
  }

  Widget _boardRow(double price, int? sellQty, int? buyQty, String side) {
    final color = side == 'SELL' ? const Color(0xFFDC2626) : const Color(0xFF16A34A);
    return Container(height: 34, margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: [
        Expanded(child: Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.only(right: 8), child: Text(sellQty != null ? '${sellQty}株' : '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))))),
        SizedBox(width: 90, child: Text('¥${price.toStringAsFixed(0)}', textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))),
        Expanded(child: Padding(padding: const EdgeInsets.only(left: 8), child: Text(buyQty != null ? '${buyQty}株' : '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)))),
      ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.go('/companies'), icon: const Icon(Icons.arrow_back)),
        title: Text(widget.code), backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  const SizedBox(height: 16), ElevatedButton(onPressed: _load, child: const Text('再試行')),
                ]))
              : Column(children: [
                  _buildHeader(),
                  Container(color: Colors.white, child: TabBar(
                    controller: _tabCtrl,
                    labelColor: const Color(0xFF2563EB), unselectedLabelColor: Colors.black54,
                    indicatorColor: const Color(0xFF2563EB),
                    tabs: const [Tab(text: '概要'), Tab(text: 'チャート'), Tab(text: 'ニュース'), Tab(text: '企業情報'), Tab(text: '売買')],
                  )),
                  Expanded(child: TabBarView(controller: _tabCtrl, children: [
                    _buildSummaryTab(), _buildChartTab(), _buildNewsTab(), _buildCompanyTab(), _buildTradingTab(),
                  ])),
                ]),
    );
  }
}
