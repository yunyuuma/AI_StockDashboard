package com.example.stockapp.dto;
import lombok.Data;
@Data
public class CompanyProfileRequest {
    private String companyName;
    private String description;
    private String website;
    private String market;
    private String industry;
    private String mapQuery;
    private String trendsKeyword;
}
