package com.example.stockapp.service;

import com.example.stockapp.dto.admin.*;
import com.example.stockapp.dto.CompanyProfileAdminResponse;
import com.example.stockapp.dto.CompanyProfileRequest;
import com.example.stockapp.entity.*;
import com.example.stockapp.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AdminDashboardService {
    private final UserRepository userRepository;
    private final StockRepository stockRepository;
    private final CompanyProfileRepository companyProfileRepository;
    private final TradeRepository tradeRepository;

    public AdminDashboardResponse getDashboard() {
        return new AdminDashboardResponse(
                userRepository.count(),
                stockRepository.count(),
                companyProfileRepository.count(),
                tradeRepository.count()
        );
    }
}
