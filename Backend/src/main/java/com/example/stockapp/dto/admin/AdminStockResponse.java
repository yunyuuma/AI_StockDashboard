package com.example.stockapp.dto.admin;
import lombok.AllArgsConstructor;
import lombok.Data;
@Data @AllArgsConstructor
public class AdminStockResponse {
    private String code;
    private String name;
    private String market;
    private String sector;
}
