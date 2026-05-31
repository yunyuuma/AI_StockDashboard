package com.example.stockapp.dto;
import lombok.Data;
@Data
public class FavoriteRequest {
    private Long userId;
    private String stockCode;
}
