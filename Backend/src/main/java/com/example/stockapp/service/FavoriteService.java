package com.example.stockapp.service;

import com.example.stockapp.dto.FavoriteRequest;
import com.example.stockapp.dto.FavoriteResponse;
import com.example.stockapp.entity.Favorite;
import com.example.stockapp.repository.FavoriteRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FavoriteService {

    private final FavoriteRepository favoriteRepository;

    public List<FavoriteResponse> getFavorites(Long userId) {
        return favoriteRepository.findByUserId(userId)
                .stream()
                .map(f -> new FavoriteResponse(f.getId(), f.getUserId(), f.getStockCode()))
                .toList();
    }

    @Transactional
    public FavoriteResponse addFavorite(FavoriteRequest req) {
        if (favoriteRepository.existsByUserIdAndStockCode(req.getUserId(), req.getStockCode())) {
            return favoriteRepository.findByUserIdAndStockCode(req.getUserId(), req.getStockCode())
                    .map(f -> new FavoriteResponse(f.getId(), f.getUserId(), f.getStockCode()))
                    .orElseThrow();
        }
        Favorite f = new Favorite();
        f.setUserId(req.getUserId());
        f.setStockCode(req.getStockCode());
        Favorite saved = favoriteRepository.save(f);
        return new FavoriteResponse(saved.getId(), saved.getUserId(), saved.getStockCode());
    }

    @Transactional
    public void deleteFavorite(Long userId, String stockCode) {
        favoriteRepository.findByUserIdAndStockCode(userId, stockCode)
                .ifPresent(favoriteRepository::delete);
    }
}
