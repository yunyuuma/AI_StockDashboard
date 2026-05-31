package com.example.stockapp.service;

import com.example.stockapp.dto.ai.AiChatResponse;
import com.example.stockapp.dto.trading.PortfolioSummaryResponse;
import com.example.stockapp.entity.Stock;
import com.example.stockapp.repository.StockRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.math.BigDecimal;
import java.util.*;

@Slf4j
@Service
@RequiredArgsConstructor
public class OllamaChatService {

    private final PortfolioService portfolioService;
    private final StockRepository stockRepository;
    private final StockPriceService stockPriceService;

    private final RestTemplate restTemplate = new RestTemplate();
    private static final String OLLAMA_BASE = "http://localhost:11434";
    private static final String OLLAMA_URL  = OLLAMA_BASE + "/api/generate";

    // 使用モデル（pullされていなければ自動検出）
    private volatile String resolvedModel = null;

    @Transactional(readOnly = true)
    public AiChatResponse chat(Long userId, String message, String stockCode) {
        if (message == null || message.isBlank())
            throw new IllegalArgumentException("メッセージを入力してください。");

        PortfolioSummaryResponse pf = portfolioService.getPortfolio(userId);
        String stockCtx = buildStockContext(stockCode);
        String prompt = buildPrompt(message, pf, stockCtx);

        String model = getModel();
        if (model == null) {
            return new AiChatResponse(
                "Ollamaにモデルがインストールされていません。\n" +
                "ターミナルで以下を実行してください：\n\n" +
                "  ollama pull qwen2.5:1.5b\n\n" +
                "その後、再度メッセージを送ってください。"
            );
        }

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", model);
        body.put("prompt", prompt);
        body.put("stream", false);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        try {
            ResponseEntity<Map> res = restTemplate.exchange(
                    OLLAMA_URL, HttpMethod.POST, new HttpEntity<>(body, headers), Map.class);
            Map<?, ?> rb = res.getBody();
            if (rb == null || rb.get("response") == null)
                return new AiChatResponse("AIから回答を取得できませんでした。");
            String answer = rb.get("response").toString().trim();
            return new AiChatResponse(answer.isBlank() ? "AIから空の回答が返されました。" : answer);
        } catch (Exception e) {
            log.error("Ollama chat error: {}", e.getMessage());
            return new AiChatResponse(
                "Ollama接続エラー: " + e.getMessage() + "\n\n" +
                "確認事項：\n" +
                "1. ollama serve が起動しているか\n" +
                "2. http://localhost:11434 にアクセスできるか\n" +
                "3. ollama list でモデルが表示されるか"
            );
        }
    }

    /** インストール済みモデルを自動検出。優先順: qwen2.5:1.5b → 最初のモデル */
    private String getModel() {
        if (resolvedModel != null) return resolvedModel;
        try {
            ResponseEntity<Map> res = restTemplate.getForEntity(OLLAMA_BASE + "/api/tags", Map.class);
            Map<?, ?> body = res.getBody();
            if (body == null) return null;
            List<?> models = (List<?>) body.get("models");
            if (models == null || models.isEmpty()) return null;

            for (Object m : models) {
                String name = (String) ((Map<?, ?>) m).get("name");
                if (name != null && name.startsWith("qwen2.5")) {
                    resolvedModel = name;
                    log.info("Ollama: using model {}", resolvedModel);
                    return resolvedModel;
                }
            }
            // qwen2.5が無ければ最初のモデル
            resolvedModel = (String) ((Map<?, ?>) models.get(0)).get("name");
            log.info("Ollama: qwen2.5 not found, using first model: {}", resolvedModel);
            return resolvedModel;
        } catch (Exception e) {
            log.warn("Ollama: could not list models: {}", e.getMessage());
            return null;
        }
    }

    private String buildStockContext(String stockCode) {
        if (stockCode == null || stockCode.isBlank()) return "銘柄指定なし";
        String code = normalize(stockCode);
        Stock stock = stockRepository.findById(code).orElse(null);
        if (stock == null) return "銘柄コード: " + code + "\n銘柄情報: DBに登録されていません。";
        BigDecimal price = stockPriceService.getCurrentPrice(code);
        String priceText = (price == null || price.compareTo(BigDecimal.ZERO) <= 0)
                ? "取得不可" : price.toPlainString() + " 円";
        return """
                銘柄コード: %s
                銘柄名: %s
                市場: %s
                業種: %s
                現在価格: %s
                """.formatted(stock.getCode(), stock.getName(), stock.getMarket(), stock.getSector(), priceText);
    }

    private String buildPrompt(String message, PortfolioSummaryResponse pf, String stockCtx) {
        return """
                あなたは株価アプリ内のAI相談アシスタントです。
                投資助言ではなく、疑似売買学習用の分析補助として回答してください。
                断定的に「買うべき」「売るべき」とは言わず、確認ポイント・リスク・考え方を日本語で簡潔に説明してください。

                【現在表示中の銘柄情報】
                %s

                【ユーザーのポートフォリオ情報】
                総資産: %s 円 / 現金: %s 円 / 保有評価額: %s 円
                総損益: %s 円 (%s%%) / 日次損益: %s 円 / 最大DD率: %s%%

                【ユーザーの質問】
                %s

                【回答ルール】
                ・日本語で回答
                ・初心者にも分かりやすく
                ・投資判断を断定しない
                ・最後に「※これは投資助言ではなく学習用コメントです。」を付ける
                """.formatted(
                stockCtx,
                pf.getTotalAsset(), pf.getCash(), pf.getStockValue(),
                pf.getProfitLoss(), pf.getProfitLossRate(),
                pf.getDailyProfitLoss(), pf.getMaxDrawdownRate(),
                message);
    }

    private String normalize(String code) {
        if (code == null) return "";
        String v = code.trim().toUpperCase();
        if (v.length() == 5 && v.endsWith("0")) v = v.substring(0, 4);
        return v;
    }
}
