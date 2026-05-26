package com.example.stockapp.service;

import com.example.stockapp.dto.trading.*;
import com.example.stockapp.entity.*;
import com.example.stockapp.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class TradingService {

    private final CashBalanceRepository cashBalanceRepository;
    private final PositionRepository positionRepository;
    private final TradeOrderRepository tradeOrderRepository;
    private final TradeRepository tradeRepository;
    private final StockRepository stockRepository;
    private final StockPriceService stockPriceService;
    private final PortfolioSnapshotService portfolioSnapshotService;

    private static final BigDecimal INITIAL_CASH = new BigDecimal("1000000");

    @Transactional(readOnly = true)
    public TradingSummaryResponse summary(Long userId) {
        BigDecimal cash = getOrCreateCash(userId).getCash();
        int positions = positionRepository.findByUserIdOrderByStockCodeAsc(userId).size();
        int trades = tradeRepository.findByUserIdOrderByTradedAtDesc(userId).size();
        return new TradingSummaryResponse(cash, positions, trades);
    }

    @Transactional(readOnly = true)
    public List<PositionResponse> positions(Long userId) {
        return positionRepository.findByUserIdOrderByStockCodeAsc(userId).stream().map(p -> {
            Stock stock = stockRepository.findById(p.getStockCode()).orElse(null);
            BigDecimal cur = stockPriceService.getCurrentPrice(p.getStockCode());
            if (cur == null || cur.compareTo(BigDecimal.ZERO) <= 0) cur = p.getAveragePrice();
            BigDecimal valuation = cur.multiply(BigDecimal.valueOf(p.getQuantity()));
            BigDecimal cost = p.getAveragePrice().multiply(BigDecimal.valueOf(p.getQuantity()));
            BigDecimal pl = valuation.subtract(cost);
            BigDecimal plRate = cost.compareTo(BigDecimal.ZERO) > 0
                    ? pl.multiply(BigDecimal.valueOf(100)).divide(cost, 2, RoundingMode.HALF_UP)
                    : BigDecimal.ZERO;
            return new PositionResponse(
                    p.getStockCode(), stock != null ? stock.getName() : "",
                    stock != null ? stock.getMarket() : "", stock != null ? stock.getSector() : "",
                    p.getQuantity(), p.getAveragePrice(), cur, valuation, pl, plRate);
        }).toList();
    }

    @Transactional(readOnly = true)
    public List<TradeResponse> trades(Long userId) {
        return tradeRepository.findByUserIdOrderByTradedAtDesc(userId).stream().map(t -> {
            Stock stock = stockRepository.findById(t.getStockCode()).orElse(null);
            return new TradeResponse(t.getId(), t.getStockCode(),
                    stock != null ? stock.getName() : "", stock != null ? stock.getMarket() : "",
                    stock != null ? stock.getSector() : "", t.getSide(), t.getQuantity(), t.getPrice(), t.getTradedAt());
        }).toList();
    }

    @Transactional(readOnly = true)
    public List<OrderListResponse> orders(Long userId) {
        return tradeOrderRepository.findByUserIdOrderByOrderedAtDesc(userId).stream()
                .map(this::toOrderListResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<OrderListResponse> openOrders(Long userId) {
        return tradeOrderRepository.findByUserIdAndStatusOrderByOrderedAtDesc(userId, "OPEN").stream()
                .map(this::toOrderListResponse).toList();
    }

    @Transactional
    public OrderResponse order(Long userId, OrderRequest req) {
        validate(req);
        String code = normalizeCode(req.getStockCode());
        String side = req.getSide().trim().toUpperCase();
        String type = req.getOrderType().trim().toUpperCase();
        BigDecimal cur = req.getCurrentPrice();

        boolean fill = shouldFill(side, type, cur, req.getLimitPrice(), req.getStopPrice());

        TradeOrder order = new TradeOrder();
        order.setUserId(userId);
        order.setStockCode(code);
        order.setSide(side);
        order.setOrderType(type);
        order.setQuantity(req.getQuantity());
        order.setLimitPrice(req.getLimitPrice());
        order.setStopPrice(req.getStopPrice());
        order.setCurrentPrice(cur);
        order.setAlgoType("NONE");
        order.setStatus(fill ? "FILLED" : "OPEN");
        order.setOrderedAt(LocalDateTime.now());
        if (fill) order.setFilledAt(LocalDateTime.now());

        TradeOrder saved = tradeOrderRepository.save(order);
        if (fill) executeTrade(userId, saved, cur);

        return new OrderResponse(saved.getId(), code, side, type, req.getQuantity(),
                req.getLimitPrice(), req.getStopPrice(), cur,
                saved.getStatus(), fill ? "注文が約定しました。" : "注文を受付しました。");
    }

    @Transactional
    public OrderResponse algoOrder(Long userId, AlgoOrderRequest req) {
        validateAlgo(req);
        String algoType = req.getAlgoType().trim().toUpperCase();
        String code = normalizeCode(req.getStockCode());
        String groupId = UUID.randomUUID().toString();

        return switch (algoType) {
            case "IFD" -> createIfd(userId, req, code, groupId);
            case "OCO" -> createOco(userId, req, code, groupId);
            case "IFDOCO" -> createIfdOco(userId, req, code, groupId);
            default -> throw new IllegalArgumentException("アルゴ注文種別が不正です。");
        };
    }

    @Transactional
    public void cancelOrder(Long userId, Long orderId) {
        TradeOrder order = tradeOrderRepository.findById(orderId)
                .orElseThrow(() -> new IllegalArgumentException("注文が存在しません。"));
        if (!order.getUserId().equals(userId)) throw new IllegalArgumentException("他ユーザーの注文は取消できません。");
        if (!"OPEN".equals(order.getStatus()) && !"WAITING".equals(order.getStatus()))
            throw new IllegalArgumentException("未約定注文以外は取消できません。");
        order.setStatus("CANCELED");
        order.setCanceledAt(LocalDateTime.now());
        tradeOrderRepository.save(order);
    }

    @Transactional
    public int checkOpenOrders(Long userId) {
        List<TradeOrder> orders = tradeOrderRepository.findByUserIdAndStatusOrderByOrderedAtDesc(userId, "OPEN");
        int count = 0;
        for (TradeOrder o : orders) {
            BigDecimal cur = o.getCurrentPrice();
            if (cur == null || cur.compareTo(BigDecimal.ZERO) <= 0) continue;
            if (!shouldFill(o.getSide(), o.getOrderType(), cur, o.getLimitPrice(), o.getStopPrice())) continue;
            o.setStatus("FILLED");
            o.setFilledAt(LocalDateTime.now());
            tradeOrderRepository.save(o);
            executeTrade(userId, o, cur);
            afterAlgoFilled(o);
            count++;
        }
        return count;
    }

    public OrderBookResponse pseudoBoard(String stockCode, BigDecimal cur) {
        BigDecimal p = cur.setScale(0, RoundingMode.HALF_UP);
        var sell = List.of(
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("1.050")).setScale(0, RoundingMode.HALF_UP), 100),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("1.040")).setScale(0, RoundingMode.HALF_UP), 200),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("1.030")).setScale(0, RoundingMode.HALF_UP), 300),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("1.020")).setScale(0, RoundingMode.HALF_UP), 500),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("1.015")).setScale(0, RoundingMode.HALF_UP), 700),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("1.010")).setScale(0, RoundingMode.HALF_UP), 900),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("1.005")).setScale(0, RoundingMode.HALF_UP), 1200));
        var buy = List.of(
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("0.995")).setScale(0, RoundingMode.HALF_UP), 1100),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("0.990")).setScale(0, RoundingMode.HALF_UP), 800),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("0.985")).setScale(0, RoundingMode.HALF_UP), 650),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("0.980")).setScale(0, RoundingMode.HALF_UP), 500),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("0.970")).setScale(0, RoundingMode.HALF_UP), 300),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("0.960")).setScale(0, RoundingMode.HALF_UP), 200),
                new OrderBookResponse.BoardRow(p.multiply(new BigDecimal("0.950")).setScale(0, RoundingMode.HALF_UP), 100));
        return new OrderBookResponse(normalizeCode(stockCode), cur, sell, buy);
    }

    // ── private helpers ──────────────────────────────────────────────────────

    private OrderResponse createIfd(Long userId, AlgoOrderRequest req, String code, String groupId) {
        TradeOrder entry = saveOrder(userId, code, "BUY", "LIMIT", req.getQuantity(),
                req.getEntryLimitPrice(), null, req.getCurrentPrice(), "IFD", groupId, null, "OPEN");
        TradeOrder profit = saveOrder(userId, code, "SELL", "LIMIT", req.getQuantity(),
                req.getProfitLimitPrice(), null, req.getCurrentPrice(), "IFD", groupId, entry.getId(), "WAITING");
        return new OrderResponse(entry.getId(), code, "BUY", "LIMIT", req.getQuantity(),
                req.getEntryLimitPrice(), null, req.getCurrentPrice(), "OPEN", "IFD注文を受付しました。");
    }

    private OrderResponse createOco(Long userId, AlgoOrderRequest req, String code, String groupId) {
        TradeOrder profit = saveOrder(userId, code, "SELL", "LIMIT", req.getQuantity(),
                req.getProfitLimitPrice(), null, req.getCurrentPrice(), "OCO", groupId, null, "OPEN");
        saveOrder(userId, code, "SELL", "STOP", req.getQuantity(),
                null, req.getStopPrice(), req.getCurrentPrice(), "OCO", groupId, null, "OPEN");
        return new OrderResponse(profit.getId(), code, "SELL", "LIMIT", req.getQuantity(),
                req.getProfitLimitPrice(), req.getStopPrice(), req.getCurrentPrice(), "OPEN", "OCO注文を受付しました。");
    }

    private OrderResponse createIfdOco(Long userId, AlgoOrderRequest req, String code, String groupId) {
        TradeOrder entry = saveOrder(userId, code, "BUY", "LIMIT", req.getQuantity(),
                req.getEntryLimitPrice(), null, req.getCurrentPrice(), "IFDOCO", groupId, null, "OPEN");
        saveOrder(userId, code, "SELL", "LIMIT", req.getQuantity(),
                req.getProfitLimitPrice(), null, req.getCurrentPrice(), "IFDOCO", groupId, entry.getId(), "WAITING");
        saveOrder(userId, code, "SELL", "STOP", req.getQuantity(),
                null, req.getStopPrice(), req.getCurrentPrice(), "IFDOCO", groupId, entry.getId(), "WAITING");
        return new OrderResponse(entry.getId(), code, "BUY", "LIMIT", req.getQuantity(),
                req.getEntryLimitPrice(), req.getStopPrice(), req.getCurrentPrice(), "OPEN", "IFDOCO注文を受付しました。");
    }

    private TradeOrder saveOrder(Long userId, String code, String side, String type, int qty,
            BigDecimal limit, BigDecimal stop, BigDecimal cur, String algo, String groupId, Long parentId, String status) {
        TradeOrder o = new TradeOrder();
        o.setUserId(userId); o.setStockCode(code); o.setSide(side); o.setOrderType(type);
        o.setQuantity(qty); o.setLimitPrice(limit); o.setStopPrice(stop); o.setCurrentPrice(cur);
        o.setAlgoType(algo); o.setGroupId(groupId); o.setParentOrderId(parentId);
        o.setStatus(status); o.setOrderedAt(LocalDateTime.now());
        return tradeOrderRepository.save(o);
    }

    private void afterAlgoFilled(TradeOrder filled) {
        String algo = filled.getAlgoType();
        if (algo == null || algo.isBlank() || "NONE".equals(algo)) return;
        tradeOrderRepository.findByParentOrderIdAndStatus(filled.getId(), "WAITING").forEach(c -> {
            c.setStatus("OPEN"); tradeOrderRepository.save(c);
        });
        if ("OCO".equals(algo) || "IFDOCO".equals(algo)) {
            tradeOrderRepository.findByGroupIdAndStatus(filled.getGroupId(), "OPEN").forEach(o -> {
                if (!o.getId().equals(filled.getId())) {
                    o.setStatus("CANCELED"); o.setCanceledAt(LocalDateTime.now()); tradeOrderRepository.save(o);
                }
            });
        }
    }

    private void executeTrade(Long userId, TradeOrder order, BigDecimal price) {
        if ("BUY".equals(order.getSide())) buy(userId, order, price);
        else sell(userId, order, price);
        Trade t = new Trade();
        t.setOrderId(order.getId()); t.setUserId(userId); t.setStockCode(order.getStockCode());
        t.setSide(order.getSide()); t.setQuantity(order.getQuantity()); t.setPrice(price);
        t.setTradedAt(LocalDateTime.now());
        tradeRepository.save(t);
        portfolioSnapshotService.saveSnapshot(userId, order.getStockCode() + " " + ("BUY".equals(order.getSide()) ? "買い" : "売り"));
    }

    private void buy(Long userId, TradeOrder order, BigDecimal price) {
        CashBalance cash = getOrCreateCash(userId);
        BigDecimal amount = price.multiply(BigDecimal.valueOf(order.getQuantity()));
        if (cash.getCash().compareTo(amount) < 0) throw new IllegalArgumentException("仮想残高が不足しています。");
        cash.setCash(cash.getCash().subtract(amount));
        cashBalanceRepository.save(cash);

        Position pos = positionRepository.findByUserIdAndStockCode(userId, order.getStockCode())
                .orElseGet(() -> { Position p = new Position(); p.setUserId(userId); p.setStockCode(order.getStockCode()); p.setQuantity(0); p.setAveragePrice(BigDecimal.ZERO); return p; });
        int oldQty = pos.getQuantity();
        int newQty = oldQty + order.getQuantity();
        BigDecimal newAvg = pos.getAveragePrice().multiply(BigDecimal.valueOf(oldQty)).add(amount)
                .divide(BigDecimal.valueOf(newQty), 2, RoundingMode.HALF_UP);
        pos.setQuantity(newQty); pos.setAveragePrice(newAvg);
        positionRepository.save(pos);
    }

    private void sell(Long userId, TradeOrder order, BigDecimal price) {
        Position pos = positionRepository.findByUserIdAndStockCode(userId, order.getStockCode())
                .orElseThrow(() -> new IllegalArgumentException("保有していない銘柄です。"));
        if (pos.getQuantity() < order.getQuantity()) throw new IllegalArgumentException("保有数量が不足しています。");
        pos.setQuantity(pos.getQuantity() - order.getQuantity());
        if (pos.getQuantity() == 0) positionRepository.delete(pos);
        else positionRepository.save(pos);

        CashBalance cash = getOrCreateCash(userId);
        cash.setCash(cash.getCash().add(price.multiply(BigDecimal.valueOf(order.getQuantity()))));
        cashBalanceRepository.save(cash);
    }

    private boolean shouldFill(String side, String type, BigDecimal cur, BigDecimal limit, BigDecimal stop) {
        if ("MARKET".equals(type)) return true;
        if ("LIMIT".equals(type)) return "BUY".equals(side) ? cur.compareTo(limit) <= 0 : cur.compareTo(limit) >= 0;
        if ("STOP".equals(type)) return "BUY".equals(side) ? cur.compareTo(stop) >= 0 : cur.compareTo(stop) <= 0;
        return false;
    }

    private CashBalance getOrCreateCash(Long userId) {
        return cashBalanceRepository.findByUserId(userId).orElseGet(() -> {
            CashBalance c = new CashBalance(); c.setUserId(userId); c.setCash(INITIAL_CASH);
            return cashBalanceRepository.save(c);
        });
    }

    private OrderListResponse toOrderListResponse(TradeOrder o) {
        Stock stock = stockRepository.findById(o.getStockCode()).orElse(null);
        return new OrderListResponse(o.getId(), o.getStockCode(),
                stock != null ? stock.getName() : "", stock != null ? stock.getMarket() : "",
                stock != null ? stock.getSector() : "", o.getSide(), o.getOrderType(), o.getQuantity(),
                o.getLimitPrice(), o.getStopPrice(), o.getCurrentPrice(), o.getStatus(),
                o.getOrderedAt(), o.getFilledAt(), o.getCanceledAt(), o.getAlgoType(), o.getGroupId(), o.getParentOrderId());
    }

    private void validate(OrderRequest req) {
        if (req.getStockCode() == null || req.getStockCode().isBlank()) throw new IllegalArgumentException("銘柄コードは必須です。");
        if (req.getQuantity() == null || req.getQuantity() <= 0) throw new IllegalArgumentException("数量は1以上で入力してください。");
        if (req.getCurrentPrice() == null || req.getCurrentPrice().compareTo(BigDecimal.ZERO) <= 0) throw new IllegalArgumentException("現在価格が不正です。");
        String side = req.getSide() == null ? "" : req.getSide().trim().toUpperCase();
        if (!side.equals("BUY") && !side.equals("SELL")) throw new IllegalArgumentException("売買区分が不正です。");
        String type = req.getOrderType() == null ? "" : req.getOrderType().trim().toUpperCase();
        if (!type.equals("MARKET") && !type.equals("LIMIT") && !type.equals("STOP")) throw new IllegalArgumentException("注文種別が不正です。");
        if (type.equals("LIMIT") && (req.getLimitPrice() == null || req.getLimitPrice().compareTo(BigDecimal.ZERO) <= 0)) throw new IllegalArgumentException("指値価格は必須です。");
        if (type.equals("STOP") && (req.getStopPrice() == null || req.getStopPrice().compareTo(BigDecimal.ZERO) <= 0)) throw new IllegalArgumentException("逆指値価格は必須です。");
    }

    private void validateAlgo(AlgoOrderRequest req) {
        if (req.getStockCode() == null || req.getStockCode().isBlank()) throw new IllegalArgumentException("銘柄コードは必須です。");
        if (req.getQuantity() == null || req.getQuantity() <= 0) throw new IllegalArgumentException("数量は1以上で入力してください。");
        if (req.getCurrentPrice() == null || req.getCurrentPrice().compareTo(BigDecimal.ZERO) <= 0) throw new IllegalArgumentException("現在価格が不正です。");
        String algo = req.getAlgoType() == null ? "" : req.getAlgoType().trim().toUpperCase();
        if (!algo.equals("IFD") && !algo.equals("OCO") && !algo.equals("IFDOCO")) throw new IllegalArgumentException("アルゴ注文種別が不正です。");
    }

    private String normalizeCode(String code) {
        if (code == null) return "";
        String v = code.trim().toUpperCase();
        if (v.length() == 5 && v.endsWith("0")) v = v.substring(0, 4);
        return v;
    }
}
