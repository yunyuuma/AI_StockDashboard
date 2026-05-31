package com.example.stockapp.service;

import com.example.stockapp.dto.ai.AiStockAdvisorResponse;
import com.example.stockapp.entity.*;
import com.example.stockapp.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AiStockAdvisorService {

    private final StockRepository stockRepository;
    private final PositionRepository positionRepository;
    private final TradeRepository tradeRepository;
    private final StockPriceService stockPriceService;

    @Transactional(readOnly = true)
    public AiStockAdvisorResponse analyze(Long userId, String rawCode) {
        String code = normalize(rawCode);
        Stock stock = stockRepository.findById(code)
                .orElseThrow(() -> new IllegalArgumentException("銘柄が存在しません。"));
        BigDecimal cur = stockPriceService.getCurrentPrice(code);
        Position pos = positionRepository.findByUserIdAndStockCode(userId, code).orElse(null);
        long tradeCount = tradeRepository.findByUserIdOrderByTradedAtDesc(userId).stream()
                .filter(t -> code.equals(t.getStockCode())).count();

        List<String> analysis = new ArrayList<>();
        List<String> checkPoints = new ArrayList<>();
        List<String> warnings = new ArrayList<>();

        analysis.add(stock.getName() + " は " + stock.getMarket() + " 市場の " + stock.getSector() + " に属する銘柄です。");

        if (cur != null && cur.compareTo(BigDecimal.ZERO) > 0) {
            analysis.add("現在価格は " + cur.toPlainString() + " 円です。現在値を基準に売買判断を行えます。");
        } else {
            analysis.add("現在価格が取得できていません。価格情報がない状態での売買判断には注意が必要です。");
            warnings.add("現在価格が取得できないため、分析精度が下がっています。");
        }

        if (pos != null && pos.getQuantity() > 0) {
            BigDecimal avg = pos.getAveragePrice();
            BigDecimal valPrice = (cur != null && cur.compareTo(BigDecimal.ZERO) > 0) ? cur : avg;
            BigDecimal pl = valPrice.subtract(avg).multiply(BigDecimal.valueOf(pos.getQuantity()));
            analysis.add("この銘柄を " + pos.getQuantity() + " 株保有しています。平均取得単価は " + avg.toPlainString() + " 円です。");
            if (pl.compareTo(BigDecimal.ZERO) >= 0) {
                analysis.add("現在は含み益の状態です。利益確定ラインを決めておくと判断しやすくなります。");
            } else {
                analysis.add("現在は含み損の状態です。損切りラインや保有継続理由を確認してください。");
                warnings.add("含み損が出ているため、追加購入よりもリスク確認を優先してください。");
            }
        } else {
            analysis.add("この銘柄は現在保有していません。新規購入候補として確認できます。");
        }

        analysis.add(tradeCount == 0
                ? "この銘柄の売買履歴はまだありません。"
                : "この銘柄の売買履歴は " + tradeCount + " 件あります。過去の売買タイミングを振り返れます。");

        String sec = stock.getSector() != null ? stock.getSector() : "";
        if (sec.contains("情報")) checkPoints.add("情報・通信系は成長期待がある一方、業績変動やバリュエーションに注意が必要です。");
        else if (sec.contains("医薬")) checkPoints.add("医薬品系は研究開発・承認・特許などの材料で株価が動きやすいです。");
        else checkPoints.add("同じ業種の銘柄と比較して、株価水準や成長性を確認してください。");
        checkPoints.add("買う前に、現在価格・直近ニュース・業績指標・チャートの方向性を確認してください。");
        checkPoints.add("売買する場合は、利確価格と損切価格を先に決めておくと判断が安定します。");

        warnings.add("この分析は投資助言ではなく、疑似売買学習用のコメントです。");

        String risk = decideRisk(stock, pos, cur);
        String summary = switch (risk) {
            case "HIGH" -> "この銘柄は注意度が高めです。価格取得状況・含み損・業種リスクを確認してください。";
            case "MIDDLE" -> "この銘柄は標準的な確認が必要です。売買前にニュースとチャートを確認してください。";
            default -> "この銘柄は比較的確認しやすい状態です。基本情報と売買ルールを確認してください。";
        };

        return new AiStockAdvisorResponse(stock.getCode(), stock.getName(), stock.getMarket(), stock.getSector(),
                risk, summary, analysis, checkPoints, warnings);
    }

    private String decideRisk(Stock stock, Position pos, BigDecimal cur) {
        if (cur == null || cur.compareTo(BigDecimal.ZERO) <= 0) return "HIGH";
        if (pos != null && pos.getQuantity() > 0 && pos.getAveragePrice().compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal diff = cur.subtract(pos.getAveragePrice())
                    .multiply(BigDecimal.valueOf(100))
                    .divide(pos.getAveragePrice(), 2, java.math.RoundingMode.HALF_UP);
            if (diff.compareTo(BigDecimal.valueOf(-10)) <= 0) return "HIGH";
            if (diff.compareTo(BigDecimal.valueOf(-5)) <= 0) return "MIDDLE";
        }
        if (stock.getMarket() != null && stock.getMarket().contains("グロース")) return "MIDDLE";
        return "LOW";
    }

    private String normalize(String code) {
        if (code == null) return "";
        String v = code.trim().toUpperCase();
        if (v.length() == 5 && v.endsWith("0")) v = v.substring(0, 4);
        return v;
    }
}
