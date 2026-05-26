package com.example.stockapp.dto.trading;
import lombok.AllArgsConstructor;
import lombok.Data;
import java.math.BigDecimal;
@Data @AllArgsConstructor
public class PositionResponse {
    private String stockCode;
    private String stockName;
    private String market;
    private String sector;
    private Integer quantity;
    private BigDecimal averagePrice;
    private BigDecimal currentPrice;
    private BigDecimal valuationAmount;
    private BigDecimal profitLoss;
    private BigDecimal profitLossRate;
}
