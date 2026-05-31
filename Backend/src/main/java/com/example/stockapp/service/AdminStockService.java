package com.example.stockapp.service;

import com.example.stockapp.dto.admin.*;
import com.example.stockapp.entity.Stock;
import com.example.stockapp.repository.StockRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service @RequiredArgsConstructor
public class AdminStockService {
    private final StockRepository stockRepository;

    public List<AdminStockResponse> getAll() {
        return stockRepository.findAll().stream()
                .map(s -> new AdminStockResponse(s.getCode(), s.getName(), s.getMarket(), s.getSector()))
                .toList();
    }

    @Transactional
    public AdminStockResponse create(AdminStockRequest req) {
        Stock s = new Stock();
        s.setCode(req.getCode()); s.setName(req.getName()); s.setMarket(req.getMarket()); s.setSector(req.getSector());
        stockRepository.save(s);
        return new AdminStockResponse(s.getCode(), s.getName(), s.getMarket(), s.getSector());
    }

    @Transactional
    public void delete(String code) { stockRepository.deleteById(code); }
}
