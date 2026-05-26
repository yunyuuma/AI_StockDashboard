package com.example.stockapp.service;

import com.example.stockapp.dto.auth.*;
import com.example.stockapp.entity.User;
import com.example.stockapp.repository.UserRepository;
import com.example.stockapp.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final TwoFactorChallengeService twoFactorChallengeService;

    @Transactional
    public AuthResponse register(RegisterRequest req) {
        validatePassword(req.getPassword());
        String email = req.getEmail().trim().toLowerCase();
        if (userRepository.existsByEmail(email)) {
            throw new IllegalArgumentException("このメールアドレスは既に登録されています。");
        }
        User user = new User();
        user.setUserName(req.getUserName().trim());
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(req.getPassword()));
        user.setRole("USER");
        user.setTwoFactorEnabled(req.isTwoFactorEnabled());
        User saved = userRepository.save(user);
        String token = jwtService.generateToken(saved.getId(), saved.getEmail(), saved.getRole());
        return AuthResponse.loginSuccess(saved.getId(), saved.getUserName(), saved.getEmail(), saved.getRole(), token);
    }

    @Transactional
    public AuthResponse login(LoginRequest req) {
        String email = req.getEmail().trim().toLowerCase();
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("メールアドレスまたはパスワードが違います。"));
        if (!passwordEncoder.matches(req.getPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("メールアドレスまたはパスワードが違います。");
        }
        if (user.isTwoFactorEnabled()) {
            String challengeId = twoFactorChallengeService.createChallenge(user);
            return AuthResponse.twoFactorRequired(user.getId(), user.getUserName(), user.getEmail(), user.getRole(), challengeId);
        }
        String token = jwtService.generateToken(user.getId(), user.getEmail(), user.getRole());
        return AuthResponse.loginSuccess(user.getId(), user.getUserName(), user.getEmail(), user.getRole(), token);
    }

    @Transactional
    public AuthResponse verifyTwoFactor(TwoFactorVerifyRequest req) {
        Long userId = twoFactorChallengeService.verify(req.getChallengeId(), req.getCode());
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが存在しません。"));
        String token = jwtService.generateToken(user.getId(), user.getEmail(), user.getRole());
        return AuthResponse.loginSuccess(user.getId(), user.getUserName(), user.getEmail(), user.getRole(), token);
    }

    @Transactional
    public void resendTwoFactor(TwoFactorResendRequest req) {
        Long userId = twoFactorChallengeService.getUserId(req.getChallengeId());
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("ユーザーが存在しません。"));
        twoFactorChallengeService.createChallenge(user);
    }

    private void validatePassword(String password) {
        if (password == null || password.length() < 8 || password.length() > 16) {
            throw new IllegalArgumentException("パスワードは8〜16文字で入力してください。");
        }
        boolean hasLetter = password.matches(".*[a-zA-Z].*");
        boolean hasDigit = password.matches(".*\\d.*");
        boolean hasSymbol = password.matches(".*[^a-zA-Z0-9].*");
        int count = (hasLetter ? 1 : 0) + (hasDigit ? 1 : 0) + (hasSymbol ? 1 : 0);
        if (count < 2) {
            throw new IllegalArgumentException("パスワードは英字・数字・記号のうち2種類以上を含めてください。");
        }
    }
}
