package com.example.stockapp.controller;

import com.example.stockapp.dto.user.*;
import com.example.stockapp.security.CustomUserPrincipal;
import com.example.stockapp.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController @RequestMapping("/api/users/me")
@RequiredArgsConstructor @CrossOrigin(origins = "*")
public class UserController {
    private final UserService userService;

    @GetMapping
    public ResponseEntity<UserProfileResponse> get(@AuthenticationPrincipal CustomUserPrincipal p) {
        return ResponseEntity.ok(userService.getMyProfile(p));
    }
    @PutMapping
    public ResponseEntity<UserProfileResponse> update(@AuthenticationPrincipal CustomUserPrincipal p, @Valid @RequestBody UserUpdateRequest req) {
        return ResponseEntity.ok(userService.updateMyProfile(p, req));
    }
    @PutMapping("/password")
    public ResponseEntity<Map<String, String>> pwd(@AuthenticationPrincipal CustomUserPrincipal p, @Valid @RequestBody PasswordUpdateRequest req) {
        userService.updateMyPassword(p, req);
        return ResponseEntity.ok(Map.of("message", "パスワードを更新しました。"));
    }
    @PutMapping("/2fa")
    public ResponseEntity<UserProfileResponse> twoFa(@AuthenticationPrincipal CustomUserPrincipal p, @RequestBody TwoFactorSettingRequest req) {
        return ResponseEntity.ok(userService.updateTwoFactorSetting(p, req));
    }
}
