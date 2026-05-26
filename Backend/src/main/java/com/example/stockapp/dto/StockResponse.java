package com.example.stockapp.dto;
import lombok.AllArgsConstructor;
import lombok.Data;
@Data @AllArgsConstructor
public class StockResponse {
    private String code;
    private String name;
    private String market;
    private String sector;
}
