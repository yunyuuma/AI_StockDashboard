package com.example.stockapp.dto;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import java.util.List;
@Data
public class JQuantsFinSummaryResponse {
    @JsonProperty("statements") private List<Statement> statements;
    @Data
    public static class Statement {
        @JsonProperty("DisclosedDate") private String disclosedDate;
        @JsonProperty("DisclosedTime") private String disclosedTime;
        @JsonProperty("TypeOfDocument") private String typeOfDocument;
        @JsonProperty("CurrentPeriodEndDate") private String currentPeriodEndDate;
        @JsonProperty("NetSales") private String netSales;
        @JsonProperty("OperatingProfit") private String operatingProfit;
        @JsonProperty("OrdinaryProfit") private String ordinaryProfit;
        @JsonProperty("Profit") private String profit;
        @JsonProperty("EarningsPerShare") private String earningsPerShare;
        @JsonProperty("ForecastNetSales") private String forecastNetSales;
        @JsonProperty("ForecastOperatingProfit") private String forecastOperatingProfit;
        @JsonProperty("ForecastOrdinaryProfit") private String forecastOrdinaryProfit;
        @JsonProperty("ForecastProfit") private String forecastProfit;
    }
}
