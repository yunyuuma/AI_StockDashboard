package com.example.stockapp.service;

import com.example.stockapp.client.JQuantsClient;
import com.example.stockapp.config.JQuantsProperties;
import com.example.stockapp.dto.JQuantsMasterResponse;
import com.example.stockapp.dto.StockResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class StockService {

    private final JQuantsClient jQuantsClient;
    private final JQuantsProperties properties;

    private volatile List<StockResponse> cachedStocks = List.of();
    private volatile Instant cachedAt = Instant.EPOCH;

    public List<StockResponse> getStocks(int page, int size, String q, String market) {
        List<StockResponse> all = getAllStocksCached();
        String kw = q == null ? "" : q.trim().toLowerCase();
        String mf = market == null ? "" : market.trim();

        List<StockResponse> filtered = all.stream()
                .filter(s -> kw.isEmpty()
                        || s.getCode().toLowerCase().contains(kw)
                        || s.getName().toLowerCase().contains(kw)
                        || s.getSector().toLowerCase().contains(kw)
                        || s.getMarket().toLowerCase().contains(kw))
                .filter(s -> mf.isEmpty() || s.getMarket().equals(mf))
                .toList();

        int from = Math.max(page, 0) * Math.max(1, Math.min(size, 50));
        int safeSize = Math.max(1, Math.min(size, 50));
        if (from >= filtered.size()) return List.of();
        return filtered.subList(from, Math.min(from + safeSize, filtered.size()));
    }

    public List<StockResponse> getAllStocks() {
        return getAllStocksCached();
    }

    public String findNameByCode(String code) {
        return getAllStocks().stream()
                .filter(s -> s.getCode().equalsIgnoreCase(code))
                .findFirst()
                .map(StockResponse::getName)
                .orElse(code);
    }

    public synchronized void reloadCache() {
        cachedStocks = fetchFromJQuants();
        cachedAt = Instant.now();
    }

    private List<StockResponse> getAllStocksCached() {
        Instant expires = cachedAt.plusSeconds(properties.getCacheMinutes() * 60);
        if (cachedStocks.isEmpty() || Instant.now().isAfter(expires)) {
            synchronized (this) {
                expires = cachedAt.plusSeconds(properties.getCacheMinutes() * 60);
                if (cachedStocks.isEmpty() || Instant.now().isAfter(expires)) {
                    cachedStocks = fetchFromJQuants();
                    cachedAt = Instant.now();
                }
            }
        }
        return cachedStocks;
    }

    private List<StockResponse> fetchFromJQuants() {
        List<StockResponse> result = new ArrayList<>();
        Set<String> seen = new HashSet<>();
        String paginationKey = null;
        int pageCount = 0;

        log.info("StockService: Starting J-Quants fetch...");

        while (true) {
            JQuantsMasterResponse res = jQuantsClient.getMaster(paginationKey);
            pageCount++;
            if (res == null || res.getData() == null || res.getData().isEmpty()) {
                log.warn("StockService: getMaster returned null/empty on page {}", pageCount);
                break;
            }

            log.info("StockService: Page {} - {} items", pageCount, res.getData().size());

            for (JQuantsMasterResponse.Item item : res.getData()) {
                String code = normalizeCode(safe(item.getCode()).trim());
                String name = safe(item.getCompanyName()).trim();
                String mkt = safe(item.getMarketCodeName()).trim();
                String sec = safe(item.getSector33CodeName()).trim();

                if (code.isEmpty() || name.isEmpty() || mkt.isEmpty() || sec.isEmpty()) continue;
                if ("TOKYO PRO MARKET".equals(mkt) || "その他".equals(mkt)) continue;
                if (!seen.add(code)) continue;

                result.add(new StockResponse(code, name, mkt, sec));
            }

            if (res.getPaginationKey() == null || res.getPaginationKey().isBlank() || pageCount >= 100) break;
            paginationKey = res.getPaginationKey();
        }

        result.sort(Comparator.comparing(StockResponse::getCode));
        log.info("StockService: Loaded {} stocks from J-Quants", result.size());
        return result;
    }

    private String normalizeCode(String raw) {
        if (raw == null || raw.isBlank()) return "";
        String code = raw.trim().toUpperCase();
        if (code.length() == 5 && code.endsWith("0")) code = code.substring(0, 4);
        if (!code.matches("[0-9A-Z]{4}")) return "";
        return code;
    }

    private String safe(String v) { return v == null ? "" : v; }
}
