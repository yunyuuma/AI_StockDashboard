package com.example.stockapp.service;

import com.example.stockapp.dto.CompanyProfileAdminResponse;
import com.example.stockapp.dto.CompanyProfileRequest;
import com.example.stockapp.entity.CompanyProfile;
import com.example.stockapp.repository.CompanyProfileRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service @RequiredArgsConstructor
public class AdminCompanyProfileService {
    private final CompanyProfileRepository repo;

    public List<CompanyProfileAdminResponse> getAll() {
        return repo.findAll().stream().map(this::toResponse).toList();
    }

    public CompanyProfileAdminResponse getOne(String code) {
        return repo.findById(code).map(this::toResponse)
                .orElse(new CompanyProfileAdminResponse(code, "", "", "", "", "", "", ""));
    }

    @Transactional
    public CompanyProfileAdminResponse save(String code, CompanyProfileRequest req) {
        CompanyProfile cp = repo.findById(code).orElseGet(() -> { CompanyProfile p = new CompanyProfile(); p.setStockCode(code); return p; });
        cp.setCompanyName(req.getCompanyName()); cp.setDescription(req.getDescription()); cp.setWebsite(req.getWebsite());
        cp.setMarket(req.getMarket()); cp.setIndustry(req.getIndustry()); cp.setMapQuery(req.getMapQuery()); cp.setTrendsKeyword(req.getTrendsKeyword());
        return toResponse(repo.save(cp));
    }

    private CompanyProfileAdminResponse toResponse(CompanyProfile cp) {
        return new CompanyProfileAdminResponse(cp.getStockCode(), s(cp.getCompanyName()), s(cp.getDescription()),
                s(cp.getWebsite()), s(cp.getMarket()), s(cp.getIndustry()), s(cp.getMapQuery()), s(cp.getTrendsKeyword()));
    }

    private String s(String v) { return v == null ? "" : v; }
}
