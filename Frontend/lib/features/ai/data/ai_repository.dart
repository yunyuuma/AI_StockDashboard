import '../../stock/data/api_base.dart';
import '../domain/ai_models.dart';

class AiRepository {
  Future<AiAdvisorResult> fetchPortfolioAdvice() async =>
      AiAdvisorResult.fromJson(await apiGet('/api/ai-advisor'));
  Future<AiStockAdvisorResult> fetchStockAdvice(String code) async =>
      AiStockAdvisorResult.fromJson(await apiGet('/api/ai-advisor/stocks/$code'));
  Future<AiTradingReviewResult> fetchTradingReview() async =>
      AiTradingReviewResult.fromJson(await apiGet('/api/ai-advisor/trading-review'));
  Future<String> chat(String message, {String? stockCode}) async {
    final body = <String, dynamic>{'message': message};
    if (stockCode != null) body['stockCode'] = stockCode;
    final d = await apiPost('/api/ai-advisor/chat', body);
    return d['reply'] ?? '';
  }
}
