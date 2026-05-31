class TradingSummary {
  final double cash;
  final int positionCount, tradeCount;
  TradingSummary({required this.cash, required this.positionCount, required this.tradeCount});
  factory TradingSummary.fromJson(Map<String, dynamic> j) => TradingSummary(
    cash: (j['cash'] ?? 0).toDouble(), positionCount: j['positionCount'] ?? 0, tradeCount: j['tradeCount'] ?? 0);
}

class TradingPosition {
  final String stockCode, stockName, market, sector;
  final int quantity;
  final double averagePrice, currentPrice, valuationAmount, profitLoss, profitLossRate;
  TradingPosition({required this.stockCode, required this.stockName, required this.market,
    required this.sector, required this.quantity, required this.averagePrice,
    required this.currentPrice, required this.valuationAmount, required this.profitLoss, required this.profitLossRate});
  factory TradingPosition.fromJson(Map<String, dynamic> j) => TradingPosition(
    stockCode: j['stockCode'] ?? '', stockName: j['stockName'] ?? '',
    market: j['market'] ?? '', sector: j['sector'] ?? '',
    quantity: j['quantity'] ?? 0, averagePrice: (j['averagePrice'] ?? 0).toDouble(),
    currentPrice: (j['currentPrice'] ?? 0).toDouble(), valuationAmount: (j['valuationAmount'] ?? 0).toDouble(),
    profitLoss: (j['profitLoss'] ?? 0).toDouble(), profitLossRate: (j['profitLossRate'] ?? 0).toDouble());
}

class TradingTrade {
  final int tradeId, quantity;
  final String stockCode, stockName, market, sector, side, tradedAt;
  final double price;
  TradingTrade({required this.tradeId, required this.stockCode, required this.stockName,
    required this.market, required this.sector, required this.side, required this.quantity,
    required this.price, required this.tradedAt});
  factory TradingTrade.fromJson(Map<String, dynamic> j) => TradingTrade(
    tradeId: j['tradeId'] ?? 0, stockCode: j['stockCode'] ?? '', stockName: j['stockName'] ?? '',
    market: j['market'] ?? '', sector: j['sector'] ?? '', side: j['side'] ?? '',
    quantity: j['quantity'] ?? 0, price: (j['price'] ?? 0).toDouble(), tradedAt: j['tradedAt'] ?? '');
}

class TradingOrder {
  final int orderId, quantity;
  final String stockCode, stockName, market, sector, side, orderType, status, algoType;
  final double? limitPrice, stopPrice, currentPrice;
  final String? orderedAt, filledAt, canceledAt, groupId;
  final int? parentOrderId;
  TradingOrder({required this.orderId, required this.stockCode, required this.stockName,
    required this.market, required this.sector, required this.side, required this.orderType,
    required this.quantity, required this.status, required this.algoType,
    this.limitPrice, this.stopPrice, this.currentPrice,
    this.orderedAt, this.filledAt, this.canceledAt, this.groupId, this.parentOrderId});
  factory TradingOrder.fromJson(Map<String, dynamic> j) => TradingOrder(
    orderId: j['orderId'] ?? 0, stockCode: j['stockCode'] ?? '', stockName: j['stockName'] ?? '',
    market: j['market'] ?? '', sector: j['sector'] ?? '', side: j['side'] ?? '',
    orderType: j['orderType'] ?? '', quantity: j['quantity'] ?? 0, status: j['status'] ?? '',
    algoType: j['algoType'] ?? 'NONE', limitPrice: _d(j['limitPrice']), stopPrice: _d(j['stopPrice']),
    currentPrice: _d(j['currentPrice']), orderedAt: j['orderedAt']?.toString(),
    filledAt: j['filledAt']?.toString(), canceledAt: j['canceledAt']?.toString(),
    groupId: j['groupId'], parentOrderId: j['parentOrderId']);
  static double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
}

class OrderBookRow {
  final double price;
  final int quantity;
  OrderBookRow({required this.price, required this.quantity});
  factory OrderBookRow.fromJson(Map<String, dynamic> j) => OrderBookRow(
    price: (j['price'] ?? 0).toDouble(), quantity: j['quantity'] ?? 0);
}

class OrderBook {
  final String stockCode;
  final double currentPrice;
  final List<OrderBookRow> sellBoard, buyBoard;
  OrderBook({required this.stockCode, required this.currentPrice, required this.sellBoard, required this.buyBoard});
  factory OrderBook.fromJson(Map<String, dynamic> j) => OrderBook(
    stockCode: j['stockCode'] ?? '', currentPrice: (j['currentPrice'] ?? 0).toDouble(),
    sellBoard: (j['sellBoard'] as List? ?? []).map((e) => OrderBookRow.fromJson(e)).toList(),
    buyBoard: (j['buyBoard'] as List? ?? []).map((e) => OrderBookRow.fromJson(e)).toList());
}

class OrderResult {
  final int orderId;
  final String status, message;
  OrderResult({required this.orderId, required this.status, required this.message});
  factory OrderResult.fromJson(Map<String, dynamic> j) => OrderResult(
    orderId: j['orderId'] ?? 0, status: j['status'] ?? '', message: j['message'] ?? '');
}
