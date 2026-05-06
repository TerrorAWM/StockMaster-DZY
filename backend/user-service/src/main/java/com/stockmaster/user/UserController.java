package com.stockmaster.user;

import com.stockmaster.common.ApiResponse;
import com.stockmaster.common.JwtUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.Duration;
import java.util.List;
import java.util.Map;

@RestController
public class UserController {
    private final UserRepository users;
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    @Value("${stockmaster.jwt.secret:stockmaster-dev-secret}")
    private String jwtSecret;

    public UserController(UserRepository users) {
        this.users = users;
    }

    @PostMapping("/auth/login")
    public ApiResponse<Map<String, Object>> login(@RequestBody LoginRequest request) {
        UserAccount user = users.findByUsername(request.username()).orElse(null);
        if (user == null || !user.isEnabled() || !encoder.matches(request.password(), user.getPasswordHash())) {
            return ApiResponse.fail("用户名或密码错误");
        }
        String token = JwtUtils.createToken(user.getId(), user.getUsername(), user.getRole(), jwtSecret, Duration.ofHours(8));
        return ApiResponse.ok(Map.of("token", token, "username", user.getUsername(), "role", user.getRole()));
    }

    @GetMapping("/users")
    public ApiResponse<List<Map<String, Object>>> list(@RequestHeader("X-Role") String role) {
        if (!"admin".equals(role)) {
            return ApiResponse.fail("无权限");
        }
        return ApiResponse.ok(users.findAll().stream()
                .map(u -> Map.<String, Object>of("id", u.getId(), "username", u.getUsername(), "role", u.getRole(), "enabled", u.isEnabled()))
                .toList());
    }

    @PostMapping("/users")
    public ApiResponse<Map<String, Object>> create(@RequestHeader("X-Role") String role, @RequestBody CreateUserRequest request) {
        if (!"admin".equals(role)) {
            return ApiResponse.fail("无权限");
        }
        if (users.existsByUsername(request.username())) {
            return ApiResponse.fail("用户名已存在");
        }
        UserAccount user = new UserAccount();
        user.setUsername(request.username());
        user.setRole(request.role() == null ? "staff" : request.role());
        user.setPasswordHash(encoder.encode(request.password()));
        user.setEnabled(true);
        UserAccount saved = users.save(user);
        return ApiResponse.ok(Map.of("id", saved.getId(), "username", saved.getUsername(), "role", saved.getRole()));
    }

    @PatchMapping("/users/{id}/status")
    public ApiResponse<Void> status(@RequestHeader("X-Role") String role, @PathVariable Long id, @RequestBody StatusRequest request) {
        if (!"admin".equals(role)) {
            return ApiResponse.fail("无权限");
        }
        UserAccount user = users.findById(id).orElse(null);
        if (user == null) {
            return ApiResponse.fail("用户不存在");
        }
        user.setEnabled(request.enabled());
        users.save(user);
        return ApiResponse.ok(null);
    }

    @Bean
    CommandLineRunner seedAdmin(UserRepository repository) {
        return args -> {
            if (!repository.existsByUsername("admin")) {
                UserAccount admin = new UserAccount();
                admin.setUsername("admin");
                admin.setRole("admin");
                admin.setPasswordHash(encoder.encode("admin123"));
                admin.setEnabled(true);
                repository.save(admin);
            }
        };
    }

    public record LoginRequest(String username, String password) {}
    public record CreateUserRequest(String username, String password, String role) {}
    public record StatusRequest(boolean enabled) {}
}

