import '../../stock/data/api_base.dart';
import '../domain/portfolio_models.dart';

class PortfolioRepository {
  Future<PortfolioSummary> fetchPortfolio() async =>
      PortfolioSummary.fromJson(await apiGet('/api/trading/portfolio'));
}
