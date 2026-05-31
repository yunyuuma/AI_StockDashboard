package com.example.stockapp.client;

import com.example.stockapp.config.JQuantsProperties;
import com.example.stockapp.dto.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

/**
 * J-Quants API v2 クライアント（2025-12-22以降登録アカウント対応）
 * api-key をそのまま Bearer トークンとして使用する。
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class JQuantsClient {

    private final JQuantsProperties props;
    private final RestTemplate restTemplate = new RestTemplate();

    private HttpHeaders authHeaders() {
        HttpHeaders h = new HttpHeaders();
        h.set("Authorization", "Bearer " + props.getApiKey());
        return h;
    }

    public JQuantsMasterResponse getMaster(String paginationKey) {
        String url = props.getBaseUrl() + "/listed/info";
        if (paginationKey != null && !paginationKey.isBlank())
            url += "?pagination_key=" + paginationKey;
        try {
            return get(url, JQuantsMasterResponse.class);
        } catch (Exception e) {
            log.error("getMaster failed: {}", e.getMessage());
            return null;
        }
    }

    public JQuantsDailyBarsResponse getDailyBars(String code, String from, String to) {
        String url = props.getBaseUrl() + "/prices/daily_quotes?code=" + code
                + "&date_from=" + from + "&date_to=" + to;
        try {
            return get(url, JQuantsDailyBarsResponse.class);
        } catch (Exception e) {
            log.warn("getDailyBars({}) failed: {}", code, e.getMessage());
            return null;
        }
    }

    public JQuantsFinSummaryResponse getFinSummary(String code) {
        String url = props.getBaseUrl() + "/fins/statements?code=" + code;
        try {
            return get(url, JQuantsFinSummaryResponse.class);
        } catch (Exception e) {
            log.warn("getFinSummary({}) failed: {}", code, e.getMessage());
            return null;
        }
    }

    public JQuantsDividendResponse getDividend(String code) {
        String url = props.getBaseUrl() + "/fins/dividend?code=" + code;
        try {
            return get(url, JQuantsDividendResponse.class);
        } catch (Exception e) {
            log.warn("getDividend({}) failed: {}", code, e.getMessage());
            return null;
        }
    }

    private <T> T get(String url, Class<T> type) {
        return restTemplate.exchange(
                url, HttpMethod.GET, new HttpEntity<>(authHeaders()), type).getBody();
    }
}
