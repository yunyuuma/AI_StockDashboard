package com.example.stockapp.controller;

import com.example.stockapp.dto.CompanyProfileAdminResponse;
import com.example.stockapp.dto.CompanyProfileRequest;
import com.example.stockapp.service.AdminCompanyProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController @RequestMapping("/api/admin/company-profiles")
@RequiredArgsConstructor @CrossOrigin(origins = "*")
public class AdminCompanyProfileController {
    private final AdminCompanyProfileService service;

    @GetMapping
    public List<CompanyProfileAdminResponse> list() { return service.getAll(); }
    @GetMapping("/{code}")
    public CompanyProfileAdminResponse get(@PathVariable String code) { return service.getOne(code); }
    @PutMapping("/{code}")
    public CompanyProfileAdminResponse save(@PathVariable String code, @RequestBody CompanyProfileRequest req) { return service.save(code, req); }
}
