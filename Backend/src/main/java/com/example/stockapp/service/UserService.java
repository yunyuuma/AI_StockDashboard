package com.example.stockapp.service;

import com.example.stockapp.dto.user.*;
import com.example.stockapp.entity.User;
import com.example.stockapp.repository.UserRepository;
import com.example.stockapp.security.CustomUserPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public UserProfileResponse getMyProfile(CustomUserPrincipal principal) {
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが存在しません。"));
        return toResponse(user);
    }

    @Transactional
    public UserProfileResponse updateMyProfile(CustomUserPrincipal principal, UserUpdateRequest req) {
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが存在しません。"));
        user.setUserName(req.getUserName().trim());
        return toResponse(userRepository.save(user));
    }

    @Transactional
    public void updateMyPassword(CustomUserPrincipal principal, PasswordUpdateRequest req) {
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが存在しません。"));
        if (!passwordEncoder.matches(req.getCurrentPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("現在のパスワードが正しくありません。");
        }
        user.setPasswordHash(passwordEncoder.encode(req.getNewPassword()));
        userRepository.save(user);
    }

    @Transactional
    public UserProfileResponse updateTwoFactorSetting(CustomUserPrincipal principal, TwoFactorSettingRequest req) {
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが存在しません。"));
        user.setTwoFactorEnabled(req.isTwoFactorEnabled());
        return toResponse(userRepository.save(user));
    }

    private UserProfileResponse toResponse(User user) {
        return new UserProfileResponse(user.getId(), user.getUserName(), user.getEmail(), user.getRole(), user.isTwoFactorEnabled());
    }
}
