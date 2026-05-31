package com.example.stockapp.dto.admin;
import lombok.Data;
@Data
public class AdminStockRequest {
    private String code;
    private String name;
    private String market;
    private String sector;
}
