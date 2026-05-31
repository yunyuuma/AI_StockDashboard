import '../domain/company.dart';
import 'api_base.dart';

class StockRepository {
  Future<List<Company>> fetchStocks({int page = 0, int size = 30, String? q, String? market}) async {
    String path = '/api/stocks?page=$page&size=$size';
    if (q != null && q.trim().isNotEmpty) path += '&q=${Uri.encodeQueryComponent(q.trim())}';
    if (market != null && market.trim().isNotEmpty) path += '&market=${Uri.encodeQueryComponent(market.trim())}';
    final data = await apiGet(path);
    return (data as List).map((e) => Company.fromJson(e)).toList();
  }
}
