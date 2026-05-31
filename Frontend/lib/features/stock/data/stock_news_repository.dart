import 'api_base.dart';

class StockNews {
  final String title, link, source, publishedAt;
  StockNews({required this.title, required this.link, required this.source, required this.publishedAt});
  factory StockNews.fromJson(Map<String, dynamic> j) => StockNews(
    title: j['title'] ?? '', link: j['link'] ?? '',
    source: j['source'] ?? '', publishedAt: j['publishedAt'] ?? '');
  String get readKey => '$source:$title';
}

class StockNewsRepository {
  Future<List<StockNews>> fetchNews(String code) async {
    final d = await apiGet('/api/stocks/$code/news');
    return (d as List).map((e) => StockNews.fromJson(e)).toList();
  }
}
