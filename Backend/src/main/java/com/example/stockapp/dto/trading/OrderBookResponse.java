package com.example.stockapp.dto.trading;
import lombok.AllArgsConstructor;
import lombok.Data;
import java.math.BigDecimal;
import java.util.List;
@Data @AllArgsConstructor
public class OrderBookResponse {
    private String stockCode;
    private BigDecimal currentPrice;
    private List<BoardRow> sellBoard;
    private List<BoardRow> buyBoard;

    @Data @AllArgsConstructor
    public static class BoardRow {
        private BigDecimal price;
        private int quantity;
    }
}
