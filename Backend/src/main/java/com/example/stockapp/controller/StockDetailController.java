package com.example.stockapp.controller;

import com.example.stockapp.dto.*;
import com.example.stockapp.service.*;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController @RequestMapping("/api/stocks")
@RequiredArgsConstructor @CrossOrigin(origins = "*")
public class StockDetailController {
    private final StockDetailService stockDetailService;
    private final StockNewsService stockNewsService;

    @GetMapping("/{code}")
    public StockDetailResponse summary(@PathVariable String code) { return stockDetailService.getSummary(code); }
    @GetMapping("/{code}/chart")
    public List<StockChartPointResponse> chart(@PathVariable String code) { return stockDetailService.getChart(code); }
    @GetMapping("/{code}/metrics")
    public StockMetricsResponse metrics(@PathVariable String code) { return stockDetailService.getMetrics(code); }
    @GetMapping("/{code}/company")
    public StockCompanyResponse company(@PathVariable String code) { return stockDetailService.getCompany(code); }
    @GetMapping("/{code}/news")
    public List<StockNewsResponse> news(@PathVariable String code) { return stockNewsService.getNews(code); }
}
