package com.example.stockapp.dto.auth;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
@Data
public class RegisterRequest {
    @NotBlank private String userName;
    @Email @NotBlank private String email;
    @NotBlank private String password;
    private boolean twoFactorEnabled = false;
}
