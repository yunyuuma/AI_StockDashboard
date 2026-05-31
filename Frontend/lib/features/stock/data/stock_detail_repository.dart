import '../domain/stock_detail_models.dart';
import 'api_base.dart';

class StockDetailRepository {
  Future<StockDetailSummary> fetchSummary(String code) async {
    final d = await apiGet('/api/stocks/$code');
    return StockDetailSummary.fromJson(d);
  }
  Future<List<StockChartPoint>> fetchChart(String code) async {
    final d = await apiGet('/api/stocks/$code/chart');
    return (d as List).map((e) => StockChartPoint.fromJson(e)).toList();
  }
  Future<StockMetrics> fetchMetrics(String code) async {
    final d = await apiGet('/api/stocks/$code/metrics');
    return StockMetrics.fromJson(d);
  }
  Future<StockCompanyInfo> fetchCompany(String code) async {
    final d = await apiGet('/api/stocks/$code/company');
    return StockCompanyInfo.fromJson(d);
  }
}
