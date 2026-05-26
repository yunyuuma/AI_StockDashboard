package com.example.stockapp.dto.user;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
@Data
public class UserUpdateRequest {
    @NotBlank private String userName;
}
