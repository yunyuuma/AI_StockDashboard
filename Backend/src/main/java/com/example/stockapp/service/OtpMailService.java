package com.example.stockapp.service;

import lombok.RequiredArgsConstructor;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class OtpMailService {

    private final JavaMailSender mailSender;

    public void send(String to, String userName, String code) {
        try {
            SimpleMailMessage msg = new SimpleMailMessage();
            msg.setTo(to);
            msg.setSubject("【株式アプリ】二要素認証コード");
            msg.setText(userName + " さん\n\n認証コード: " + code + "\n\n有効期限: 5分\n\n※心当たりのない場合は無視してください。");
            mailSender.send(msg);
        } catch (Exception e) {
            // メール送信失敗してもアプリを止めない（開発環境など）
            System.err.println("OTP mail failed: " + e.getMessage());
        }
    }
}
