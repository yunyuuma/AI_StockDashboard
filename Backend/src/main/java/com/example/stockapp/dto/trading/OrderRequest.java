package com.example.stockapp.dto.trading;
import lombok.Data;
import java.math.BigDecimal;
@Data
public class OrderRequest {
    private String stockCode;
    private String side;
    private String orderType;
    private Integer quantity;
    private BigDecimal limitPrice;
    private BigDecimal stopPrice;
    private BigDecimal currentPrice;
}
