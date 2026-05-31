package com.example.stockapp.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "stocks")
@Getter @Setter
public class Stock {
    @Id
    @Column(name = "code", length = 10)
    private String code;

    @Column(name = "name", nullable = false, length = 100)
    private String name;

    @Column(name = "market", nullable = false, length = 30)
    private String market;

    @Column(name = "sector", nullable = false, length = 100)
    private String sector;
}
