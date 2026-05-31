package com.example.stockapp.dto;
import lombok.AllArgsConstructor;
import lombok.Data;
@Data @AllArgsConstructor
public class StockDetailResponse {
    private String code;
    private String name;
    private String market;
    private String industry;
    private double price;
    private double changePct;
    private double open;
    private double high;
    private double low;
    private double volume;
}
