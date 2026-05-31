package com.example.stockapp.service;

import com.example.stockapp.entity.*;
import com.example.stockapp.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class PortfolioSnapshotService {

    private final PortfolioSnapshotRepository snapshotRepository;
    private final CashBalanceRepository cashBalanceRepository;
    private final PositionRepository positionRepository;
    private final StockPriceService stockPriceService;

    private static final BigDecimal INITIAL_CASH = new BigDecimal("1000000");

    @Transactional
    public void saveSnapshot(Long userId, String eventLabel) {
        BigDecimal cash = cashBalanceRepository.findByUserId(userId)
                .map(CashBalance::getCash).orElse(INITIAL_CASH);

        BigDecimal stockValue = BigDecimal.ZERO;
        List<Position> positions = positionRepository.findByUserIdOrderByStockCodeAsc(userId);
        for (Position p : positions) {
            BigDecimal price = stockPriceService.getCurrentPrice(p.getStockCode());
            if (price == null || price.compareTo(BigDecimal.ZERO) <= 0) price = p.getAveragePrice();
            stockValue = stockValue.add(price.multiply(BigDecimal.valueOf(p.getQuantity())));
        }

        BigDecimal total = cash.add(stockValue);

        PortfolioSnapshot snap = new PortfolioSnapshot();
        snap.setUserId(userId);
        snap.setCash(cash);
        snap.setStockValue(stockValue);
        snap.setMarketValue(stockValue);
        snap.setTotalAsset(total);
        snap.setEventLabel(eventLabel);
        snap.setSnapshotAt(LocalDateTime.now());
        snapshotRepository.save(snap);
    }
}
