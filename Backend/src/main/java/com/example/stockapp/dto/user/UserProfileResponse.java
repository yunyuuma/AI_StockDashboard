package com.example.stockapp.dto.user;
import lombok.AllArgsConstructor;
import lombok.Data;
@Data @AllArgsConstructor
public class UserProfileResponse {
    private Long id;
    private String userName;
    private String email;
    private String role;
    private boolean twoFactorEnabled;
}
