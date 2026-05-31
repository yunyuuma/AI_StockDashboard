package com.example.stockapp.dto.ai;
import lombok.AllArgsConstructor;
import lombok.Data;
import java.util.List;
@Data @AllArgsConstructor
public class AiStockAdvisorResponse {
    private String code;
    private String name;
    private String market;
    private String sector;
    private String riskLevel;
    private String summary;
    private List<String> analysis;
    private List<String> checkPoints;
    private List<String> warnings;
}
