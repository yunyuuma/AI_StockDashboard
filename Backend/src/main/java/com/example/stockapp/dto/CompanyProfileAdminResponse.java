package com.example.stockapp.dto;
import lombok.AllArgsConstructor;
import lombok.Data;
@Data @AllArgsConstructor
public class CompanyProfileAdminResponse {
    private String stockCode;
    private String companyName;
    private String description;
    private String website;
    private String market;
    private String industry;
    private String mapQuery;
    private String trendsKeyword;
}
