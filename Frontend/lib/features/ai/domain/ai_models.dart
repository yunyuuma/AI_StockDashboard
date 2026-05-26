class AiAdvisorResult {
  final String riskLevel, summary;
  final List<String> portfolioAdvice, tradingAdvice, warnings;
  AiAdvisorResult({required this.riskLevel, required this.summary,
    required this.portfolioAdvice, required this.tradingAdvice, required this.warnings});
  factory AiAdvisorResult.fromJson(Map<String, dynamic> j) => AiAdvisorResult(
    riskLevel: j['riskLevel'] ?? '', summary: j['summary'] ?? '',
    portfolioAdvice: List<String>.from(j['portfolioAdvice'] ?? []),
    tradingAdvice: List<String>.from(j['tradingAdvice'] ?? []),
    warnings: List<String>.from(j['warnings'] ?? []));
}

class AiStockAdvisorResult {
  final String code, name, market, sector, riskLevel, summary;
  final List<String> analysis, checkPoints, warnings;
  AiStockAdvisorResult({required this.code, required this.name, required this.market,
    required this.sector, required this.riskLevel, required this.summary,
    required this.analysis, required this.checkPoints, required this.warnings});
  factory AiStockAdvisorResult.fromJson(Map<String, dynamic> j) => AiStockAdvisorResult(
    code: j['code'] ?? '', name: j['name'] ?? '', market: j['market'] ?? '',
    sector: j['sector'] ?? '', riskLevel: j['riskLevel'] ?? '', summary: j['summary'] ?? '',
    analysis: List<String>.from(j['analysis'] ?? []),
    checkPoints: List<String>.from(j['checkPoints'] ?? []),
    warnings: List<String>.from(j['warnings'] ?? []));
}

class AiTradingReviewResult {
  final String summary;
  final int totalTrades, buyCount, sellCount;
  final List<String> goodPoints, weakPoints, suggestions, warnings;
  AiTradingReviewResult({required this.summary, required this.totalTrades,
    required this.buyCount, required this.sellCount, required this.goodPoints,
    required this.weakPoints, required this.suggestions, required this.warnings});
  factory AiTradingReviewResult.fromJson(Map<String, dynamic> j) => AiTradingReviewResult(
    summary: j['summary'] ?? '', totalTrades: j['totalTrades'] ?? 0,
    buyCount: j['buyCount'] ?? 0, sellCount: j['sellCount'] ?? 0,
    goodPoints: List<String>.from(j['goodPoints'] ?? []),
    weakPoints: List<String>.from(j['weakPoints'] ?? []),
    suggestions: List<String>.from(j['suggestions'] ?? []),
    warnings: List<String>.from(j['warnings'] ?? []));
}
