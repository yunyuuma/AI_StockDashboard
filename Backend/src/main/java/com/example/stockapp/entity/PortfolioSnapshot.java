package com.example.stockapp.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "portfolio_snapshots")
@Getter @Setter
public class PortfolioSnapshot {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "cash", precision = 15, scale = 2)
    private BigDecimal cash;

    @Column(name = "stock_value", precision = 15, scale = 2)
    private BigDecimal stockValue;

    @Column(name = "market_value", precision = 15, scale = 2)
    private BigDecimal marketValue;

    @Column(name = "total_asset", precision = 15, scale = 2)
    private BigDecimal totalAsset;

    @Column(name = "event_label", length = 100)
    private String eventLabel;

    @Column(name = "snapshot_at")
    private LocalDateTime snapshotAt;
}
