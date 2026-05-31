package com.example.stockapp.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "jquants")
@Getter @Setter
public class JQuantsProperties {
    private String baseUrl = "https://api.jquants.com/v2";
    /** J-Quants API v2 APIキー（Bearer トークンとして直接使用） */
    private String apiKey;
    private long cacheMinutes = 60;
}
