package com.example.stockapp.dto;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import java.util.List;
@Data
public class JQuantsDailyBarsResponse {
    @JsonProperty("daily_quotes") private List<Bar> bars;
    @Data
    public static class Bar {
        @JsonProperty("Date") private String date;
        @JsonProperty("Open") private Double open;
        @JsonProperty("High") private Double high;
        @JsonProperty("Low") private Double low;
        @JsonProperty("Close") private Double close;
        @JsonProperty("Volume") private Double volume;
    }
}
