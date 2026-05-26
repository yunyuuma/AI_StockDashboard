package com.example.stockapp.dto.auth;
import lombok.AllArgsConstructor;
import lombok.Data;
@Data @AllArgsConstructor
public class AuthResponse {
    private Long userId;
    private String userName;
    private String email;
    private String role;
    private String token;
    private boolean twoFactorRequired;
    private String challengeId;

    public static AuthResponse loginSuccess(Long id, String name, String email, String role, String token) {
        return new AuthResponse(id, name, email, role, token, false, null);
    }
    public static AuthResponse twoFactorRequired(Long id, String name, String email, String role, String challengeId) {
        return new AuthResponse(id, name, email, role, null, true, challengeId);
    }
}
