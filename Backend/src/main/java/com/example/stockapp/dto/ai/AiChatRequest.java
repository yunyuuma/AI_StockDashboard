package com.example.stockapp.dto.ai;
import lombok.Data;
@Data
public class AiChatRequest {
    private String message;
    private String stockCode;
}
