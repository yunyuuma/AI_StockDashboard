package com.example.stockapp.service;

import com.example.stockapp.client.JQuantsClient;
import com.example.stockapp.dto.*;
import com.example.stockapp.entity.CompanyProfile;
import com.example.stockapp.repository.CompanyProfileRepository;
import com.example.stockapp.repository.StockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class StockDetailService {

    private final StockPriceService stockPriceService;
    private final StockRepository stockRepository;
    private final StockService stockService;
    private final JQuantsClient jQuantsClient;
    private final CompanyProfileRepository companyProfileRepository;

    public StockDetailResponse getSummary(String rawCode) {
        String code = normalizeCode(rawCode);

        // 直近5日分を取得
        String today = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        String from = LocalDate.now().minusDays(5).format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        List<JQuantsDailyBarsResponse.Bar> bars = stockPriceService.getBars(code, from, today);

        String name = stockService.findNameByCode(code);
        String market = stockRepository.findById(code).map(s -> s.getMarket()).orElse("");
        String industry = stockRepository.findById(code).map(s -> s.getSector()).orElse("");

        if (bars.isEmpty()) {
            return new StockDetailResponse(code, name, market, industry, 0, 0, 0, 0, 0, 0);
        }

        JQuantsDailyBarsResponse.Bar last = bars.get(bars.size() - 1);
        double close = last.getClose() != null ? last.getClose() : 0;
        double open = last.getOpen() != null ? last.getOpen() : 0;
        double high = last.getHigh() != null ? last.getHigh() : 0;
        double low = last.getLow() != null ? last.getLow() : 0;
        double volume = last.getVolume() != null ? last.getVolume() : 0;

        double prevClose = bars.size() >= 2
                ? (bars.get(bars.size() - 2).getClose() != null ? bars.get(bars.size() - 2).getClose() : close)
                : close;
        double changePct = prevClose > 0 ? (close - prevClose) / prevClose * 100 : 0;

        return new StockDetailResponse(code, name, market, industry, close, changePct, open, high, low, volume);
    }

    public List<StockChartPointResponse> getChart(String rawCode) {
        String code = normalizeCode(rawCode);
        String today = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        String from = LocalDate.now().minusYears(3).format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        List<JQuantsDailyBarsResponse.Bar> bars = stockPriceService.getBars(code, from, today);

        return bars.stream()
                .filter(b -> b.getClose() != null && b.getClose() > 0)
                .map(b -> new StockChartPointResponse(
                        b.getDate(),
                        b.getOpen() != null ? b.getOpen() : 0,
                        b.getHigh() != null ? b.getHigh() : 0,
                        b.getLow() != null ? b.getLow() : 0,
                        b.getClose(),
                        b.getVolume() != null ? b.getVolume() : 0
                ))
                .collect(Collectors.toList());
    }

    public StockMetricsResponse getMetrics(String rawCode) {
        String code = normalizeCode(rawCode);
        JQuantsFinSummaryResponse fin = jQuantsClient.getFinSummary(code);
        JQuantsDividendResponse div = jQuantsClient.getDividend(code);

        if (fin == null || fin.getStatements() == null || fin.getStatements().isEmpty()) {
            return new StockMetricsResponse("", "", "", "", null, null, null, null, null, null, null, null, null, null);
        }

        JQuantsFinSummaryResponse.Statement st = fin.getStatements().get(0);
        Double annualDiv = null;
        if (div != null && div.getItems() != null && !div.getItems().isEmpty()) {
            String raw = div.getItems().get(0).getForecastAnnualDividendPerShare();
            annualDiv = parseDouble(raw);
        }

        return new StockMetricsResponse(
                safe(st.getDisclosedDate()),
                safe(st.getDisclosedTime()),
                safe(st.getTypeOfDocument()),
                safe(st.getCurrentPeriodEndDate()),
                parseDouble(st.getNetSales()),
                parseDouble(st.getOperatingProfit()),
                parseDouble(st.getOrdinaryProfit()),
                parseDouble(st.getProfit()),
                parseDouble(st.getEarningsPerShare()),
                parseDouble(st.getForecastNetSales()),
                parseDouble(st.getForecastOperatingProfit()),
                parseDouble(st.getForecastOrdinaryProfit()),
                parseDouble(st.getForecastProfit()),
                annualDiv
        );
    }

    public StockCompanyResponse getCompany(String rawCode) {
        String code = normalizeCode(rawCode);
        CompanyProfile cp = companyProfileRepository.findById(code).orElse(null);

        if (cp == null) {
            String name = stockService.findNameByCode(code);
            String market = stockRepository.findById(code).map(s -> s.getMarket()).orElse("");
            String industry = stockRepository.findById(code).map(s -> s.getSector()).orElse("");
            return new StockCompanyResponse(name, "", "", market, industry, name + " 本社", name);
        }

        return new StockCompanyResponse(
                safe(cp.getCompanyName()),
                safe(cp.getDescription()),
                safe(cp.getWebsite()),
                safe(cp.getMarket()),
                safe(cp.getIndustry()),
                safe(cp.getMapQuery()),
                safe(cp.getTrendsKeyword())
        );
    }

    private Double parseDouble(String v) {
        if (v == null || v.isBlank() || v.equals("null")) return null;
        try { return Double.parseDouble(v); } catch (Exception e) { return null; }
    }

    private String safe(String v) { return v == null ? "" : v; }

    private String normalizeCode(String code) {
        if (code == null) return "";
        String v = code.trim().toUpperCase();
        if (v.length() == 5 && v.endsWith("0")) v = v.substring(0, 4);
        return v;
    }
}
