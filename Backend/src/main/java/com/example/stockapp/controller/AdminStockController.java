package com.example.stockapp.controller;

import com.example.stockapp.dto.admin.*;
import com.example.stockapp.service.AdminStockService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController @RequestMapping("/api/admin/stocks")
@RequiredArgsConstructor @CrossOrigin(origins = "*")
public class AdminStockController {
    private final AdminStockService adminStockService;

    @GetMapping
    public List<AdminStockResponse> list() { return adminStockService.getAll(); }
    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    public AdminStockResponse create(@RequestBody AdminStockRequest req) { return adminStockService.create(req); }
    @DeleteMapping("/{code}") @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable String code) { adminStockService.delete(code); }
}
