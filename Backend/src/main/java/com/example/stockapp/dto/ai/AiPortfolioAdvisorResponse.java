package com.example.stockapp.dto.ai;
import lombok.AllArgsConstructor;
import lombok.Data;
import java.util.List;
@Data @AllArgsConstructor
public class AiPortfolioAdvisorResponse {
    private String riskLevel;
    private String summary;
    private List<String> advice;
}
