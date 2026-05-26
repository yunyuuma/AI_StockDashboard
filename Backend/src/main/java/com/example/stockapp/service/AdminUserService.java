package com.example.stockapp.service;

import com.example.stockapp.dto.admin.*;
import com.example.stockapp.entity.User;
import com.example.stockapp.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service @RequiredArgsConstructor
public class AdminUserService {
    private final UserRepository userRepository;

    public List<AdminUserResponse> getAll() {
        return userRepository.findAll().stream()
                .map(u -> new AdminUserResponse(u.getId(), u.getUserName(), u.getEmail(), u.getRole(), u.isTwoFactorEnabled(), u.getCreatedAt()))
                .toList();
    }

    @Transactional
    public AdminUserResponse updateRole(Long id, AdminUserRoleUpdateRequest req) {
        User u = userRepository.findById(id).orElseThrow(() -> new IllegalArgumentException("ユーザーが存在しません。"));
        u.setRole(req.getRole());
        userRepository.save(u);
        return new AdminUserResponse(u.getId(), u.getUserName(), u.getEmail(), u.getRole(), u.isTwoFactorEnabled(), u.getCreatedAt());
    }
}
