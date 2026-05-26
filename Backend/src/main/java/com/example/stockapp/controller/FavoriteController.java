package com.example.stockapp.controller;

import com.example.stockapp.dto.*;
import com.example.stockapp.service.FavoriteService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController @RequestMapping("/api/favorites")
@RequiredArgsConstructor @CrossOrigin(origins = "*")
public class FavoriteController {
    private final FavoriteService favoriteService;

    @GetMapping
    public List<FavoriteResponse> get(@RequestParam Long userId) { return favoriteService.getFavorites(userId); }
    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    public FavoriteResponse add(@RequestBody FavoriteRequest req) { return favoriteService.addFavorite(req); }
    @DeleteMapping("/{stockCode}") @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@RequestParam Long userId, @PathVariable String stockCode) { favoriteService.deleteFavorite(userId, stockCode); }
}
