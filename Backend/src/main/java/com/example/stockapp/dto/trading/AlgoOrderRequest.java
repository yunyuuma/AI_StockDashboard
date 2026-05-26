package com.example.stockapp.dto.trading;
import lombok.Data;
import java.math.BigDecimal;
@Data
public class AlgoOrderRequest {
    private String stockCode;
    private String algoType;
    private Integer quantity;
    private BigDecimal currentPrice;
    private BigDecimal entryLimitPrice;
    private BigDecimal profitLimitPrice;
    private BigDecimal stopPrice;
}
