package com.example.stockapp.service;

import com.example.stockapp.client.JQuantsClient;
import com.example.stockapp.dto.JQuantsDailyBarsResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
@RequiredArgsConstructor
public class StockPriceService {

    private final JQuantsClient jQuantsClient;
    private final Map<String, BigDecimal> priceCache = new ConcurrentHashMap<>();

    public BigDecimal getCurrentPrice(String code) {
        if (priceCache.containsKey(code)) {
            return priceCache.get(code);
        }
        BigDecimal price = fetchLatestPrice(code);
        if (price != null && price.compareTo(BigDecimal.ZERO) > 0) {
            priceCache.put(code, price);
        }
        return price;
    }

    public List<JQuantsDailyBarsResponse.Bar> getBars(String code, String from, String to) {
        JQuantsDailyBarsResponse res = jQuantsClient.getDailyBars(code, from, to);
        if (res == null || res.getBars() == null) return List.of();
        return res.getBars();
    }

    private BigDecimal fetchLatestPrice(String code) {
        String today = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        String from = LocalDate.now().minusDays(5).format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        JQuantsDailyBarsResponse res = jQuantsClient.getDailyBars(code, from, today);
        if (res == null || res.getBars() == null || res.getBars().isEmpty()) return null;
        List<JQuantsDailyBarsResponse.Bar> bars = res.getBars();
        JQuantsDailyBarsResponse.Bar last = bars.get(bars.size() - 1);
        if (last.getClose() == null || last.getClose() <= 0) return null;
        return BigDecimal.valueOf(last.getClose());
    }
}
