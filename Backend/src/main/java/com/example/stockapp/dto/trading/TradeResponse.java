package com.example.stockapp.dto.trading;
import lombok.AllArgsConstructor;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;
@Data @AllArgsConstructor
public class TradeResponse {
    private Long tradeId;
    private String stockCode;
    private String stockName;
    private String market;
    private String sector;
    private String side;
    private Integer quantity;
    private BigDecimal price;
    private LocalDateTime tradedAt;
}
