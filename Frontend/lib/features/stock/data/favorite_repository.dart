import 'api_base.dart';

class FavoriteRepository {
  Future<List<String>> fetchFavoriteCodes(int userId) async {
    final d = await apiGet('/api/favorites?userId=$userId');
    return (d as List).map((e) => e['code'] as String).toList();
  }
  Future<void> addFavorite(int userId, String stockCode) async {
    await apiPost('/api/favorites', {'userId': userId, 'stockCode': stockCode});
  }
  Future<void> deleteFavorite(int userId, String stockCode) async {
    await apiDelete('/api/favorites/$stockCode?userId=$userId');
  }
}
