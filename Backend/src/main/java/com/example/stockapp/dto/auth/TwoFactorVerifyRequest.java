package com.example.stockapp.dto.auth;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
@Data
public class TwoFactorVerifyRequest {
    @NotBlank private String challengeId;
    @NotBlank private String code;
}
