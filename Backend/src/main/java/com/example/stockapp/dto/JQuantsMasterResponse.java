package com.example.stockapp.dto;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Data;
import java.util.List;
@Data
public class JQuantsMasterResponse {
    @JsonProperty("info") private List<Item> data;
    @JsonProperty("pagination_key") private String paginationKey;
    @Data
    public static class Item {
        @JsonProperty("Code") private String code;
        @JsonProperty("CompanyName") private String companyName;
        @JsonProperty("MarketCodeName") private String marketCodeName;
        @JsonProperty("Sector33CodeName") private String sector33CodeName;
    }
}
