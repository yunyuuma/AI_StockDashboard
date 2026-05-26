package com.example.stockapp.controller;

import com.example.stockapp.dto.auth.*;
import com.example.stockapp.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController @RequestMapping("/api/auth")
@RequiredArgsConstructor @CrossOrigin(origins = "*")
public class AuthController {
    private final AuthService authService;

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest req) {
        return ResponseEntity.ok(authService.register(req));
    }
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest req) {
        return ResponseEntity.ok(authService.login(req));
    }
    @PostMapping("/logout")
    public ResponseEntity<Map<String, String>> logout() {
        return ResponseEntity.ok(Map.of("message", "ログアウトしました。"));
    }
    @PostMapping("/2fa/verify")
    public ResponseEntity<AuthResponse> verify(@Valid @RequestBody TwoFactorVerifyRequest req) {
        return ResponseEntity.ok(authService.verifyTwoFactor(req));
    }
    @PostMapping("/2fa/resend")
    public ResponseEntity<Map<String, String>> resend(@Valid @RequestBody TwoFactorResendRequest req) {
        authService.resendTwoFactor(req);
        return ResponseEntity.ok(Map.of("message", "認証コードを再送しました。"));
    }
}
