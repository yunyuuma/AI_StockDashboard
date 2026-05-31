package com.example.stockapp.dto.user;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
@Data
public class PasswordUpdateRequest {
    @NotBlank private String currentPassword;
    @NotBlank private String newPassword;
}
