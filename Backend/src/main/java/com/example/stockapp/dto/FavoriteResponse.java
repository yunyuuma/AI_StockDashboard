package com.example.stockapp.dto;
import lombok.AllArgsConstructor;
import lombok.Data;
@Data @AllArgsConstructor
public class FavoriteResponse {
    private Long id;
    private Long userId;
    private String code;
}
