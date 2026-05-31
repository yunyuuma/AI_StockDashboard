package com.example.stockapp.controller;

import com.example.stockapp.dto.trading.*;
import com.example.stockapp.security.CustomUserPrincipal;
import com.example.stockapp.service.TradingService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController @RequestMapping("/api/trading")
@RequiredArgsConstructor @CrossOrigin(origins = "*")
public class TradingController {
    private final TradingService tradingService;

    @GetMapping("/summary")
    public TradingSummaryResponse summary(@AuthenticationPrincipal CustomUserPrincipal p) { return tradingService.summary(p.getId()); }
    @GetMapping("/positions")
    public List<PositionResponse> positions(@AuthenticationPrincipal CustomUserPrincipal p) { return tradingService.positions(p.getId()); }
    @GetMapping("/trades")
    public List<TradeResponse> trades(@AuthenticationPrincipal CustomUserPrincipal p) { return tradingService.trades(p.getId()); }
    @GetMapping("/orders")
    public List<OrderListResponse> orders(@AuthenticationPrincipal CustomUserPrincipal p) { return tradingService.orders(p.getId()); }
    @GetMapping("/orders/open")
    public List<OrderListResponse> openOrders(@AuthenticationPrincipal CustomUserPrincipal p) { return tradingService.openOrders(p.getId()); }
    @PostMapping("/orders")
    public OrderResponse order(@AuthenticationPrincipal CustomUserPrincipal p, @RequestBody OrderRequest req) { return tradingService.order(p.getId(), req); }
    @DeleteMapping("/orders/{id}")
    public Map<String, String> cancel(@AuthenticationPrincipal CustomUserPrincipal p, @PathVariable Long id) {
        tradingService.cancelOrder(p.getId(), id);
        return Map.of("message", "注文を取消しました。");
    }
    @PostMapping("/orders/check")
    public Map<String, Object> check(@AuthenticationPrincipal CustomUserPrincipal p) {
        int n = tradingService.checkOpenOrders(p.getId());
        return Map.of("message", "未約定注文を再判定しました。", "filledCount", n);
    }
    @PostMapping("/algo-orders")
    public OrderResponse algoOrder(@AuthenticationPrincipal CustomUserPrincipal p, @RequestBody AlgoOrderRequest req) { return tradingService.algoOrder(p.getId(), req); }
    @GetMapping("/order-book/{code}")
    public OrderBookResponse board(@PathVariable String code, @RequestParam BigDecimal currentPrice) { return tradingService.pseudoBoard(code, currentPrice); }
}
