package com.example.stockapp.controller;

import com.example.stockapp.dto.admin.AdminDashboardResponse;
import com.example.stockapp.service.AdminDashboardService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/api/admin/dashboard")
@RequiredArgsConstructor @CrossOrigin(origins = "*")
public class AdminDashboardController {
    private final AdminDashboardService adminDashboardService;

    @GetMapping
    public AdminDashboardResponse get() { return adminDashboardService.getDashboard(); }
}
