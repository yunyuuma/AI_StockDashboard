import '../../stock/data/api_base.dart';
import '../domain/trading_models.dart';

class TradingRepository {
  Future<TradingSummary> fetchSummary() async => TradingSummary.fromJson(await apiGet('/api/trading/summary'));
  Future<List<TradingPosition>> fetchPositions() async {
    final d = await apiGet('/api/trading/positions');
    return (d as List).map((e) => TradingPosition.fromJson(e)).toList();
  }
  Future<List<TradingTrade>> fetchTrades() async {
    final d = await apiGet('/api/trading/trades');
    return (d as List).map((e) => TradingTrade.fromJson(e)).toList();
  }
  Future<List<TradingOrder>> fetchOrders() async {
    final d = await apiGet('/api/trading/orders');
    return (d as List).map((e) => TradingOrder.fromJson(e)).toList();
  }
  Future<List<TradingOrder>> fetchOpenOrders() async {
    final d = await apiGet('/api/trading/orders/open');
    return (d as List).map((e) => TradingOrder.fromJson(e)).toList();
  }
  Future<OrderResult> placeOrder({required String stockCode, required String side,
    required String orderType, required int quantity, required double currentPrice,
    double? limitPrice, double? stopPrice}) async {
    final body = <String, dynamic>{'stockCode': stockCode, 'side': side,
      'orderType': orderType, 'quantity': quantity, 'currentPrice': currentPrice};
    if (limitPrice != null) body['limitPrice'] = limitPrice;
    if (stopPrice != null) body['stopPrice'] = stopPrice;
    return OrderResult.fromJson(await apiPost('/api/trading/orders', body));
  }
  Future<OrderResult> placeAlgoOrder({required String stockCode, required String algoType,
    required int quantity, required double currentPrice, double? entryLimitPrice,
    double? profitLimitPrice, double? stopPrice}) async {
    final body = <String, dynamic>{'stockCode': stockCode, 'algoType': algoType,
      'quantity': quantity, 'currentPrice': currentPrice};
    if (entryLimitPrice != null) body['entryLimitPrice'] = entryLimitPrice;
    if (profitLimitPrice != null) body['profitLimitPrice'] = profitLimitPrice;
    if (stopPrice != null) body['stopPrice'] = stopPrice;
    return OrderResult.fromJson(await apiPost('/api/trading/algo-orders', body));
  }
  Future<void> cancelOrder(int orderId) async => await apiDelete('/api/trading/orders/$orderId');
  Future<OrderBook> fetchOrderBook({required String stockCode, required double currentPrice}) async {
    return OrderBook.fromJson(await apiGet('/api/trading/order-book/$stockCode?currentPrice=$currentPrice'));
  }
}
