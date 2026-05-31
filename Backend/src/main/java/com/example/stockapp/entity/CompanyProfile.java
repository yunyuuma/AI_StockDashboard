package com.example.stockapp.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "company_profiles")
@Getter @Setter
public class CompanyProfile {
    @Id
    @Column(name = "stock_code", length = 10)
    private String stockCode;

    @Column(name = "company_name", length = 100)
    private String companyName;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "website", length = 255)
    private String website;

    @Column(name = "market", length = 50)
    private String market;

    @Column(name = "industry", length = 100)
    private String industry;

    @Column(name = "map_query", length = 200)
    private String mapQuery;

    @Column(name = "trends_keyword", length = 100)
    private String trendsKeyword;
}
