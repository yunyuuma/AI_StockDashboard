package com.example.stockapp.dto.trading;
import lombok.AllArgsConstructor;
import lombok.Data;
import java.math.BigDecimal;
@Data @AllArgsConstructor
public class TradingSummaryResponse {
    private BigDecimal cash;
    private int positionCount;
    private int tradeCount;
}
