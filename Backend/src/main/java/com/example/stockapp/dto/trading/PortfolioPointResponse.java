package com.example.stockapp.dto.trading;
import lombok.AllArgsConstructor;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;
@Data @AllArgsConstructor
public class PortfolioPointResponse {
    private LocalDateTime snapshotAt;
    private BigDecimal cash;
    private BigDecimal stockValue;
    private BigDecimal marketValue;
    private BigDecimal totalAsset;
    private String eventLabel;
}
