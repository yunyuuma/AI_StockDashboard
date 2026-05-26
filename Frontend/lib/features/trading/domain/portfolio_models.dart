class PortfolioPoint {
  final String? snapshotAt, eventLabel;
  final double cash, stockValue, marketValue, totalAsset;
  PortfolioPoint({this.snapshotAt, required this.cash, required this.stockValue,
    required this.marketValue, required this.totalAsset, this.eventLabel});
  factory PortfolioPoint.fromJson(Map<String, dynamic> j) => PortfolioPoint(
    snapshotAt: j['snapshotAt']?.toString(), cash: (j['cash'] ?? 0).toDouble(),
    stockValue: (j['stockValue'] ?? 0).toDouble(), marketValue: (j['marketValue'] ?? 0).toDouble(),
    totalAsset: (j['totalAsset'] ?? 0).toDouble(), eventLabel: j['eventLabel']);
}

class SectorAllocation {
  final String sector;
  final double amount, rate;
  SectorAllocation({required this.sector, required this.amount, required this.rate});
  factory SectorAllocation.fromJson(Map<String, dynamic> j) => SectorAllocation(
    sector: j['sector'] ?? '', amount: (j['amount'] ?? 0).toDouble(), rate: (j['rate'] ?? 0).toDouble());
}

class PortfolioSummary {
  final double cash, stockValue, totalAsset, profitLoss, profitLossRate;
  final double dailyProfitLoss, dailyProfitLossRate, maxDrawdown, maxDrawdownRate;
  final List<PortfolioPoint> points;
  final List<SectorAllocation> sectorAllocations;
  PortfolioSummary({required this.cash, required this.stockValue, required this.totalAsset,
    required this.profitLoss, required this.profitLossRate, required this.dailyProfitLoss,
    required this.dailyProfitLossRate, required this.maxDrawdown, required this.maxDrawdownRate,
    required this.points, required this.sectorAllocations});
  factory PortfolioSummary.fromJson(Map<String, dynamic> j) => PortfolioSummary(
    cash: (j['cash'] ?? 0).toDouble(), stockValue: (j['stockValue'] ?? 0).toDouble(),
    totalAsset: (j['totalAsset'] ?? 0).toDouble(), profitLoss: (j['profitLoss'] ?? 0).toDouble(),
    profitLossRate: (j['profitLossRate'] ?? 0).toDouble(), dailyProfitLoss: (j['dailyProfitLoss'] ?? 0).toDouble(),
    dailyProfitLossRate: (j['dailyProfitLossRate'] ?? 0).toDouble(), maxDrawdown: (j['maxDrawdown'] ?? 0).toDouble(),
    maxDrawdownRate: (j['maxDrawdownRate'] ?? 0).toDouble(),
    points: (j['points'] as List? ?? []).map((e) => PortfolioPoint.fromJson(e)).toList(),
    sectorAllocations: (j['sectorAllocations'] as List? ?? []).map((e) => SectorAllocation.fromJson(e)).toList());
}
