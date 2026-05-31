package com.example.stockapp.controller;

import com.example.stockapp.dto.ai.*;
import com.example.stockapp.security.CustomUserPrincipal;
import com.example.stockapp.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;
import java.util.Map;

@RestController @RequestMapping("/api/ai-advisor")
@RequiredArgsConstructor @CrossOrigin(origins = "*")
public class AiAdvisorController {
    private final AiAdvisorService aiAdvisorService;
    private final AiStockAdvisorService aiStockAdvisorService;
    private final AiTradingReviewService aiTradingReviewService;
    private final OllamaChatService ollamaChatService;

    @GetMapping
    public AiAdvisorResponse portfolio(@AuthenticationPrincipal CustomUserPrincipal p) {
        return aiAdvisorService.analyze(p.getId());
    }

    @GetMapping("/stocks/{code}")
    public AiStockAdvisorResponse stock(@AuthenticationPrincipal CustomUserPrincipal p, @PathVariable String code) {
        return aiStockAdvisorService.analyze(p.getId(), code);
    }

    @GetMapping("/trading-review")
    public AiTradingReviewResponse review(@AuthenticationPrincipal CustomUserPrincipal p) {
        return aiTradingReviewService.review(p.getId());
    }

    @PostMapping("/chat")
    public AiChatResponse chat(@AuthenticationPrincipal CustomUserPrincipal p, @RequestBody AiChatRequest req) {
        return ollamaChatService.chat(p.getId(), req.getMessage(), req.getStockCode());
    }

    /** Ollamaの状態確認（モデル一覧）。フロントから疎通確認に使う */
    @GetMapping("/ollama-status")
    public ResponseEntity<Map<String, Object>> ollamaStatus() {
        try {
            RestTemplate rt = new RestTemplate();
            Map body = rt.getForObject("http://localhost:11434/api/tags", Map.class);
            return ResponseEntity.ok(Map.of("ok", true, "models", body));
        } catch (Exception e) {
            return ResponseEntity.ok(Map.of("ok", false, "error", e.getMessage()));
        }
    }
}
