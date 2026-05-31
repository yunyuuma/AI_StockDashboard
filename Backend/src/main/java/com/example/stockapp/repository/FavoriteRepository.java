package com.example.stockapp.repository;

import com.example.stockapp.entity.Favorite;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface FavoriteRepository extends JpaRepository<Favorite, Long> {
    List<Favorite> findByUserId(Long userId);
    Optional<Favorite> findByUserIdAndStockCode(Long userId, String stockCode);
    boolean existsByUserIdAndStockCode(Long userId, String stockCode);
}
