package com.example.stockapp.service;

import com.example.stockapp.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
@RequiredArgsConstructor
public class TwoFactorChallengeService {

    private final OtpMailService otpMailService;

    private record Challenge(Long userId, String code, Instant expiresAt) {}

    private final Map<String, Challenge> store = new ConcurrentHashMap<>();
    private final SecureRandom random = new SecureRandom();

    public String createChallenge(User user) {
        String code = String.format("%06d", random.nextInt(1_000_000));
        String challengeId = UUID.randomUUID().toString();
        store.put(challengeId, new Challenge(user.getId(), code, Instant.now().plusSeconds(300)));
        otpMailService.send(user.getEmail(), user.getUserName(), code);
        return challengeId;
    }

    public Long verify(String challengeId, String code) {
        Challenge c = store.get(challengeId);
        if (c == null) throw new IllegalArgumentException("認証セッションが無効です。");
        if (Instant.now().isAfter(c.expiresAt())) {
            store.remove(challengeId);
            throw new IllegalArgumentException("認証コードの有効期限が切れました。");
        }
        if (!c.code().equals(code)) throw new IllegalArgumentException("認証コードが正しくありません。");
        store.remove(challengeId);
        return c.userId();
    }

    public Long getUserId(String challengeId) {
        Challenge c = store.get(challengeId);
        if (c == null) throw new IllegalArgumentException("認証セッションが無効です。");
        return c.userId();
    }
}
