package com.example.stockapp.controller;

import com.example.stockapp.dto.admin.*;
import com.example.stockapp.service.AdminUserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController @RequestMapping("/api/admin/users")
@RequiredArgsConstructor @CrossOrigin(origins = "*")
public class AdminUserController {
    private final AdminUserService adminUserService;

    @GetMapping
    public List<AdminUserResponse> list() { return adminUserService.getAll(); }

    @PutMapping("/{id}/role")
    public AdminUserResponse updateRole(@PathVariable Long id, @RequestBody AdminUserRoleUpdateRequest req) { return adminUserService.updateRole(id, req); }
}
