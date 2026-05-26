package com.example.stockapp.dto;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import java.util.List;
@Data
public class JQuantsDividendResponse {
    @JsonProperty("dividend") private List<Item> items;
    @Data
    public static class Item {
        @JsonProperty("ForecastAnnualDividendPerShare") private String forecastAnnualDividendPerShare;
    }
}
