package com.example.stockapp.service;

import com.example.stockapp.dto.trading.*;
import com.example.stockapp.entity.*;
import com.example.stockapp.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.*;

@Service
@RequiredArgsConstructor
public class PortfolioService {

    private final CashBalanceRepository cashBalanceRepository;
    private final PositionRepository positionRepository;
    private final PortfolioSnapshotRepository snapshotRepository;
    private final StockRepository stockRepository;
    private final StockPriceService stockPriceService;

    private static final BigDecimal INITIAL_CASH = new BigDecimal("1000000");

    @Transactional(readOnly = true)
    public PortfolioSummaryResponse getPortfolio(Long userId) {
        BigDecimal cash = cashBalanceRepository.findByUserId(userId)
                .map(CashBalance::getCash).orElse(INITIAL_CASH);
        BigDecimal stockValue = calcStockValue(userId);
        BigDecimal totalAsset = cash.add(stockValue);
        BigDecimal profitLoss = totalAsset.subtract(INITIAL_CASH);
        BigDecimal profitLossRate = pct(profitLoss, INITIAL_CASH);

        List<PortfolioPointResponse> points = buildPoints(userId);
        BigDecimal dailyPL = calcDailyPL(points, totalAsset);
        BigDecimal dailyPLRate = pct(dailyPL, totalAsset.subtract(dailyPL));
        BigDecimal maxDD = calcMaxDD(points);
        BigDecimal maxDDRate = calcMaxDDRate(points);
        List<SectorAllocationResponse> sectors = buildSectors(userId, stockValue);

        return new PortfolioSummaryResponse(cash, stockValue, totalAsset, profitLoss, profitLossRate,
                dailyPL, dailyPLRate, maxDD, maxDDRate, points, sectors);
    }

    private BigDecimal calcStockValue(Long userId) {
        BigDecimal total = BigDecimal.ZERO;
        for (Position p : positionRepository.findByUserIdOrderByStockCodeAsc(userId)) {
            BigDecimal price = stockPriceService.getCurrentPrice(p.getStockCode());
            if (price == null || price.compareTo(BigDecimal.ZERO) <= 0) price = p.getAveragePrice();
            total = total.add(price.multiply(BigDecimal.valueOf(p.getQuantity())));
        }
        return total;
    }

    private List<PortfolioPointResponse> buildPoints(Long userId) {
        List<PortfolioPointResponse> pts = new ArrayList<>();
        pts.add(new PortfolioPointResponse(null, INITIAL_CASH, BigDecimal.ZERO, BigDecimal.ZERO, INITIAL_CASH, "開始"));
        snapshotRepository.findByUserIdOrderBySnapshotAtAsc(userId).forEach(s ->
                pts.add(new PortfolioPointResponse(s.getSnapshotAt(), s.getCash(),
                        s.getStockValue(), s.getMarketValue(), s.getTotalAsset(), s.getEventLabel())));
        return pts;
    }

    private BigDecimal calcDailyPL(List<PortfolioPointResponse> pts, BigDecimal current) {
        if (pts.size() < 2) return BigDecimal.ZERO;
        BigDecimal prev = pts.get(pts.size() - 2).getTotalAsset();
        return prev != null && prev.compareTo(BigDecimal.ZERO) > 0 ? current.subtract(prev) : BigDecimal.ZERO;
    }

    private BigDecimal calcMaxDD(List<PortfolioPointResponse> pts) {
        BigDecimal peak = BigDecimal.ZERO, max = BigDecimal.ZERO;
        for (PortfolioPointResponse p : pts) {
            if (p.getTotalAsset() == null) continue;
            if (p.getTotalAsset().compareTo(peak) > 0) peak = p.getTotalAsset();
            BigDecimal dd = peak.subtract(p.getTotalAsset());
            if (dd.compareTo(max) > 0) max = dd;
        }
        return max;
    }

    private BigDecimal calcMaxDDRate(List<PortfolioPointResponse> pts) {
        BigDecimal peak = BigDecimal.ZERO, max = BigDecimal.ZERO;
        for (PortfolioPointResponse p : pts) {
            if (p.getTotalAsset() == null || peak.compareTo(BigDecimal.ZERO) == 0 && p.getTotalAsset().compareTo(BigDecimal.ZERO) == 0) continue;
            if (p.getTotalAsset().compareTo(peak) > 0) peak = p.getTotalAsset();
            if (peak.compareTo(BigDecimal.ZERO) <= 0) continue;
            BigDecimal rate = peak.subtract(p.getTotalAsset()).multiply(BigDecimal.valueOf(100)).divide(peak, 2, RoundingMode.HALF_UP);
            if (rate.compareTo(max) > 0) max = rate;
        }
        return max;
    }

    private List<SectorAllocationResponse> buildSectors(Long userId, BigDecimal totalStockValue) {
        if (totalStockValue.compareTo(BigDecimal.ZERO) <= 0) return List.of();
        Map<String, BigDecimal> map = new LinkedHashMap<>();
        for (Position p : positionRepository.findByUserIdOrderByStockCodeAsc(userId)) {
            String sec = stockRepository.findById(p.getStockCode()).map(Stock::getSector).orElse("未設定");
            BigDecimal price = stockPriceService.getCurrentPrice(p.getStockCode());
            if (price == null || price.compareTo(BigDecimal.ZERO) <= 0) price = p.getAveragePrice();
            map.merge(sec, price.multiply(BigDecimal.valueOf(p.getQuantity())), BigDecimal::add);
        }
        return map.entrySet().stream()
                .map(e -> new SectorAllocationResponse(e.getKey(), e.getValue(),
                        e.getValue().multiply(BigDecimal.valueOf(100)).divide(totalStockValue, 2, RoundingMode.HALF_UP)))
                .sorted((a, b) -> b.getAmount().compareTo(a.getAmount()))
                .toList();
    }

    private BigDecimal pct(BigDecimal num, BigDecimal den) {
        if (den == null || den.compareTo(BigDecimal.ZERO) == 0) return BigDecimal.ZERO;
        return num.multiply(BigDecimal.valueOf(100)).divide(den, 2, RoundingMode.HALF_UP);
    }
}
