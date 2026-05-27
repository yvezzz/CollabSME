package com.collabsme.auth;

import com.collabsme.auth.dto.*;
import com.collabsme.user.User;
import com.collabsme.user.UserRepository;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;
    private final UserRepository userRepository;

    public AuthController(AuthService authService, UserRepository userRepository) {
        this.authService = authService;
        this.userRepository = userRepository;
    }

    @PostMapping("/login/")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request.getEmail(), request.getPassword()));
    }

    @PostMapping("/register/")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(authService.register(request));
    }

    @GetMapping("/me/")
    public ResponseEntity<UserDto> me(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(UserDto.fromUser(user));
    }

    @PatchMapping("/me/")
    public ResponseEntity<UserDto> updateMe(@AuthenticationPrincipal User user,
                                             @RequestBody UserDto dto) {
        if (dto.getFirstName() != null) user.setFirstName(dto.getFirstName());
        if (dto.getLastName() != null) user.setLastName(dto.getLastName());
        if (dto.getPhoneNumber() != null) user.setPhoneNumber(dto.getPhoneNumber());
        if (dto.getBio() != null) user.setBio(dto.getBio());
        if (dto.getAvatarUrl() != null) user.setAvatarUrl(dto.getAvatarUrl());
        if (dto.getPreferences() != null) user.setPreferences(dto.getPreferences());
        userRepository.save(user);
        return ResponseEntity.ok(UserDto.fromUser(user));
    }

    @DeleteMapping("/me/")
    public ResponseEntity<Void> deleteMe(@AuthenticationPrincipal User user) {
        userRepository.delete(user);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/logout/")
    public ResponseEntity<Void> logout(@RequestBody(required = false) Map<String, String> body) {
        String refreshToken = body != null ? body.get("refresh") : null;
        authService.logout(refreshToken);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/users/")
    public ResponseEntity<?> companyUsers(@AuthenticationPrincipal User user) {
        if (user.getCompany() == null) {
            return ResponseEntity.ok(java.util.Collections.emptyList());
        }
        return ResponseEntity.ok(UserDto.fromUsers(
                userRepository.findByCompanyOrderByEmail(user.getCompany())));
    }

    @PostMapping("/password-reset/")
    public ResponseEntity<Map<String, String>> passwordReset(@Valid @RequestBody PasswordResetRequest request) {
        authService.requestPasswordReset(request.getEmail());
        return ResponseEntity.ok(Map.of("message",
                "Si un compte existe avec cet email, vous recevrez un lien de réinitialisation."));
    }

    @PostMapping("/password-reset/confirm/")
    public ResponseEntity<Map<String, String>> passwordResetConfirm(@Valid @RequestBody PasswordResetConfirm request) {
        authService.confirmPasswordReset(request.getEmail(), request.getToken(), request.getNewPassword());
        return ResponseEntity.ok(Map.of("message", "Mot de passe réinitialisé avec succès."));
    }

    @PostMapping("/token/refresh/")
    public ResponseEntity<?> refreshToken(@RequestBody Map<String, String> body) {
        try {
            String refreshToken = body != null ? body.get("refresh") : null;
            AuthResponse response = authService.refreshAccessToken(refreshToken);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", e.getMessage()));
        }
    }
}
