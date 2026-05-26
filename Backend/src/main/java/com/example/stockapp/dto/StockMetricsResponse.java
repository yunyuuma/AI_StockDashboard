package com.example.stockapp.dto;
import lombok.AllArgsConstructor;
import lombok.Data;
@Data @AllArgsConstructor
public class StockMetricsResponse {
    private String disclosedDate;
    private String disclosedTime;
    private String typeOfDocument;
    private String currentPeriodEndDate;
    private Double netSales;
    private Double operatingProfit;
    private Double ordinaryProfit;
    private Double profit;
    private Double earningsPerShare;
    private Double forecastNetSales;
    private Double forecastOperatingProfit;
    private Double forecastOrdinaryProfit;
    private Double forecastProfit;
    private Double annualDividendPerShareForecast;
}
