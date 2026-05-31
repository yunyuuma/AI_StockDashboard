import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/portfolio_repository.dart';
import '../domain/portfolio_models.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});
  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final _repo = PortfolioRepository();
  PortfolioSummary? _pf;
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final p = await _repo.fetchPortfolio();
      if (mounted) setState(() => _pf = p);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _plColor(double v) => v >= 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A);

  Widget _metricCard(String label, String value, {Color? color, String? sub}) => Card(
    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      if (sub != null) Text(sub, style: const TextStyle(fontSize: 12, color: Colors.black54)),
    ])),
  );

  Widget _buildLineChart() {
    final pts = _pf!.points.where((p) => p.snapshotAt != null).toList();
    if (pts.length < 2) return const Center(child: Text('まだ取引データがありません', style: TextStyle(color: Colors.black54)));
    final spots = pts.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.totalAsset)).toList();
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.98;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.02;
    final step = (pts.length / 5).ceil();
    return LineChart(LineChartData(
      minY: minY, maxY: maxY,
      gridData: const FlGridData(show: true),
      borderData: FlBorderData(show: true),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 56,
          getTitlesWidget: (v, _) {
            if (v >= 1e6) return Text('${(v / 1e6).toStringAsFixed(2)}M', style: const TextStyle(fontSize: 10));
            return Text('${v.toStringAsFixed(0)}', style: const TextStyle(fontSize: 9));
          })),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: step.toDouble(),
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= pts.length || i % step != 0) return const SizedBox.shrink();
            final s = pts[i].snapshotAt!;
            final label = s.length >= 10 ? s.substring(5, 10) : s;
            return Padding(padding: const EdgeInsets.only(top: 4), child: Text(label, style: const TextStyle(fontSize: 10)));
          })),
      ),
      lineBarsData: [LineChartBarData(
        spots: spots, isCurved: true, barWidth: 2.5,
        color: const Color(0xFF2563EB),
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: const Color(0x1A2563EB)),
      )],
      lineTouchData: LineTouchData(touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (spots) => spots.map((s) {
          final idx = s.x.toInt();
          final label = idx < pts.length ? (pts[idx].eventLabel ?? '') : '';
          return LineTooltipItem('¥${s.y.toStringAsFixed(0)}\n$label', const TextStyle(color: Colors.white, fontSize: 12));
        }).toList(),
      )),
    ));
  }

  Widget _buildPieChart() {
    final sectors = _pf!.sectorAllocations;
    if (sectors.isEmpty) return const Center(child: Text('保有銘柄がありません', style: TextStyle(color: Colors.black54)));
    final colors = [
      const Color(0xFF2563EB), const Color(0xFF7C3AED), const Color(0xFFDC2626),
      const Color(0xFF16A34A), const Color(0xFFF59E0B), const Color(0xFF0891B2),
      const Color(0xFFDB2777), const Color(0xFF65A30D), const Color(0xFF9333EA),
    ];
    return Column(children: [
      SizedBox(height: 200, child: PieChart(PieChartData(
        sectionsSpace: 2, centerSpaceRadius: 40,
        sections: sectors.asMap().entries.map((e) => PieChartSectionData(
          value: e.value.amount,
          color: colors[e.key % colors.length],
          radius: 70,
          title: e.value.rate >= 5 ? '${e.value.rate.toStringAsFixed(1)}%' : '',
          titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        )).toList(),
      ))),
      const SizedBox(height: 16),
      Wrap(spacing: 12, runSpacing: 6, children: sectors.asMap().entries.map((e) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('${e.value.sector} ${e.value.rate.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12)),
      ])).toList()),
    ]);
  }

  Widget _sectionCard(String title, Widget child) => Card(
    elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 14), child,
    ])),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: IconButton(onPressed: () => context.go('/trading'), icon: const Icon(Icons.arrow_back)),
        title: const Text('ポートフォリオ', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black87, elevation: 0,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _error != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('再試行')),
            ]))
          : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
              _sectionCard('総資産', Column(children: [
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('総資産', style: TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('¥${_pf!.totalAsset.toStringAsFixed(0)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${_pf!.profitLoss >= 0 ? '+' : ''}¥${_pf!.profitLoss.toStringAsFixed(0)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _plColor(_pf!.profitLoss))),
                    Text('${_pf!.profitLossRate >= 0 ? '+' : ''}${_pf!.profitLossRate.toStringAsFixed(2)}%', style: TextStyle(color: _plColor(_pf!.profitLoss))),
                  ]),
                ]),
              ])),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _metricCard('現金', '¥${_pf!.cash.toStringAsFixed(0)}')),
                const SizedBox(width: 12),
                Expanded(child: _metricCard('株式評価額', '¥${_pf!.stockValue.toStringAsFixed(0)}')),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _metricCard('日次損益', '${_pf!.dailyProfitLoss >= 0 ? '+' : ''}¥${_pf!.dailyProfitLoss.toStringAsFixed(0)}', color: _plColor(_pf!.dailyProfitLoss))),
                const SizedBox(width: 12),
                Expanded(child: _metricCard('最大DD', '¥${_pf!.maxDrawdown.toStringAsFixed(0)}', sub: '${_pf!.maxDrawdownRate.toStringAsFixed(2)}%', color: Colors.orange)),
              ]),
              const SizedBox(height: 12),
              _sectionCard('資産推移', SizedBox(height: 240, child: _buildLineChart())),
              const SizedBox(height: 12),
              _sectionCard('セクター配分', _buildPieChart()),
              const SizedBox(height: 20),
            ])),
    );
  }
}
