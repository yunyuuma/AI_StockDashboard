package com.example.stockapp.dto.ai;
import lombok.AllArgsConstructor;
import lombok.Data;
import java.util.List;
@Data @AllArgsConstructor
public class AiTradingReviewResponse {
    private String summary;
    private long totalTrades;
    private long buyCount;
    private long sellCount;
    private List<String> goodPoints;
    private List<String> weakPoints;
    private List<String> suggestions;
    private List<String> warnings;
}
