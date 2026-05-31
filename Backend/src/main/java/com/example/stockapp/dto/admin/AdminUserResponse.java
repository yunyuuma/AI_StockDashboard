package com.example.stockapp.dto.admin;
import lombok.AllArgsConstructor;
import lombok.Data;
import java.time.LocalDateTime;
@Data @AllArgsConstructor
public class AdminUserResponse {
    private Long id;
    private String userName;
    private String email;
    private String role;
    private boolean twoFactorEnabled;
    private LocalDateTime createdAt;
}
