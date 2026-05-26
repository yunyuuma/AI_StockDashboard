package com.example.stockapp.dto.trading;
import lombok.AllArgsConstructor;
import lombok.Data;
import java.math.BigDecimal;
@Data @AllArgsConstructor
public class SectorAllocationResponse {
    private String sector;
    private BigDecimal amount;
    private BigDecimal rate;
}
