package com.example.stockapp.service;

import com.example.stockapp.dto.StockNewsResponse;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class StockNewsService {

    public List<StockNewsResponse> getNews(String code) {
        List<StockNewsResponse> results = new ArrayList<>();

        // Yahoo Finance Japan ニュース
        results.addAll(fetchYahooFinanceNews(code));

        return results;
    }

    private List<StockNewsResponse> fetchYahooFinanceNews(String code) {
        List<StockNewsResponse> list = new ArrayList<>();
        try {
            String url = "https://finance.yahoo.co.jp/quote/" + code + ".T/news";
            Document doc = Jsoup.connect(url)
                    .userAgent("Mozilla/5.0")
                    .timeout(8000)
                    .get();

            Elements items = doc.select("li.ymuiListItem");
            for (Element item : items) {
                Element a = item.selectFirst("a");
                Element time = item.selectFirst("time");
                Element source = item.selectFirst("span.source");

                if (a == null) continue;

                String title = a.text().trim();
                String link = a.absUrl("href");
                String publishedAt = time != null ? time.attr("datetime") : "";
                String src = source != null ? source.text().trim() : "Yahoo Finance";

                if (title.isEmpty() || link.isEmpty()) continue;
                list.add(new StockNewsResponse(title, link, src, publishedAt));
            }
        } catch (Exception e) {
            // スクレイピング失敗は無視
        }

        // Google Newsからも取得
        list.addAll(fetchGoogleNews(code));
        return list;
    }

    private List<StockNewsResponse> fetchGoogleNews(String code) {
        List<StockNewsResponse> list = new ArrayList<>();
        try {
            String url = "https://news.google.com/rss/search?q=" + code + "+株&hl=ja&gl=JP&ceid=JP:ja";
            Document doc = Jsoup.connect(url)
                    .userAgent("Mozilla/5.0")
                    .timeout(8000)
                    .get();

            Elements items = doc.select("item");
            int count = 0;
            for (Element item : items) {
                if (count++ >= 20) break;
                String title = item.selectFirst("title") != null ? item.selectFirst("title").text() : "";
                String link = item.selectFirst("link") != null ? item.selectFirst("link").text() : "";
                String pubDate = item.selectFirst("pubDate") != null ? item.selectFirst("pubDate").text() : "";
                String source = item.selectFirst("source") != null ? item.selectFirst("source").text() : "Google News";

                if (title.isEmpty() || link.isEmpty()) continue;
                list.add(new StockNewsResponse(title, link, source, pubDate));
            }
        } catch (Exception e) {
            // 無視
        }
        return list;
    }
}
