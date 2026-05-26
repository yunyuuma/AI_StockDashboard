class StockDetailSummary {
  final String code, name, market, industry;
  final double price, changePct, open, high, low, volume;

  StockDetailSummary({
    required this.code, required this.name, required this.market,
    required this.industry, required this.price, required this.changePct,
    required this.open, required this.high, required this.low, required this.volume,
  });

  factory StockDetailSummary.fromJson(Map<String, dynamic> j) => StockDetailSummary(
    code: j['code'] ?? '', name: j['name'] ?? '',
    market: j['market'] ?? '', industry: j['industry'] ?? '',
    price: (j['price'] ?? 0).toDouble(), changePct: (j['changePct'] ?? 0).toDouble(),
    open: (j['open'] ?? 0).toDouble(), high: (j['high'] ?? 0).toDouble(),
    low: (j['low'] ?? 0).toDouble(), volume: (j['volume'] ?? 0).toDouble(),
  );
}

class StockChartPoint {
  final String date;
  final double open, high, low, close, volume;

  StockChartPoint({required this.date, required this.open, required this.high,
      required this.low, required this.close, required this.volume});

  factory StockChartPoint.fromJson(Map<String, dynamic> j) => StockChartPoint(
    date: j['date'] ?? '', open: (j['open'] ?? 0).toDouble(),
    high: (j['high'] ?? 0).toDouble(), low: (j['low'] ?? 0).toDouble(),
    close: (j['close'] ?? 0).toDouble(), volume: (j['volume'] ?? 0).toDouble(),
  );
}

class StockMetrics {
  final String disclosedDate, disclosedTime, typeOfDocument, currentPeriodEndDate;
  final double? netSales, operatingProfit, ordinaryProfit, profit, earningsPerShare;
  final double? forecastNetSales, forecastOperatingProfit, forecastOrdinaryProfit, forecastProfit;
  final double? annualDividendPerShareForecast;

  StockMetrics({
    required this.disclosedDate, required this.disclosedTime,
    required this.typeOfDocument, required this.currentPeriodEndDate,
    this.netSales, this.operatingProfit, this.ordinaryProfit, this.profit,
    this.earningsPerShare, this.forecastNetSales, this.forecastOperatingProfit,
    this.forecastOrdinaryProfit, this.forecastProfit, this.annualDividendPerShareForecast,
  });

  factory StockMetrics.fromJson(Map<String, dynamic> j) => StockMetrics(
    disclosedDate: j['disclosedDate'] ?? '', disclosedTime: j['disclosedTime'] ?? '',
    typeOfDocument: j['typeOfDocument'] ?? '', currentPeriodEndDate: j['currentPeriodEndDate'] ?? '',
    netSales: _d(j['netSales']), operatingProfit: _d(j['operatingProfit']),
    ordinaryProfit: _d(j['ordinaryProfit']), profit: _d(j['profit']),
    earningsPerShare: _d(j['earningsPerShare']), forecastNetSales: _d(j['forecastNetSales']),
    forecastOperatingProfit: _d(j['forecastOperatingProfit']),
    forecastOrdinaryProfit: _d(j['forecastOrdinaryProfit']), forecastProfit: _d(j['forecastProfit']),
    annualDividendPerShareForecast: _d(j['annualDividendPerShareForecast']),
  );

  static double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
}

class StockCompanyInfo {
  final String companyName, description, website, market, industry, mapQuery, trendsKeyword;

  StockCompanyInfo({
    required this.companyName, required this.description, required this.website,
    required this.market, required this.industry, required this.mapQuery, required this.trendsKeyword,
  });

  factory StockCompanyInfo.fromJson(Map<String, dynamic> j) => StockCompanyInfo(
    companyName: j['companyName'] ?? '', description: j['description'] ?? '',
    website: j['website'] ?? '', market: j['market'] ?? '',
    industry: j['industry'] ?? '', mapQuery: j['mapQuery'] ?? '',
    trendsKeyword: j['trendsKeyword'] ?? '',
  );
}
