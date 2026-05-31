package com.example.stockapp.dto.auth;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
@Data
public class TwoFactorResendRequest {
    @NotBlank private String challengeId;
}
