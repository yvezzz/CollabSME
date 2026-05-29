package com.collabsme.auth;

import com.collabsme.auth.dto.*;
import com.collabsme.company.Company;
import com.collabsme.company.CompanyRepository;
import com.collabsme.config.BrevoEmailService;
import com.collabsme.config.JwtTokenProvider;
import com.collabsme.exception.ResourceNotFoundException;
import com.collabsme.user.Role;
import com.collabsme.user.User;
import com.collabsme.user.UserRepository;
import io.jsonwebtoken.Claims;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    private final UserRepository userRepository;
    private final CompanyRepository companyRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final BrevoEmailService brevoEmailService;
    private final PasswordResetTokenRepository tokenRepository;

    @Value("${app.base-url}")
    private String appBaseUrl;

    public AuthService(UserRepository userRepository, CompanyRepository companyRepository,
                       PasswordEncoder passwordEncoder, JwtTokenProvider jwtTokenProvider,
                       BrevoEmailService brevoEmailService,
                       PasswordResetTokenRepository tokenRepository) {
        this.userRepository = userRepository;
        this.companyRepository = companyRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtTokenProvider = jwtTokenProvider;
        this.brevoEmailService = brevoEmailService;
        this.tokenRepository = tokenRepository;
    }

    public AuthResponse login(String email, String password) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new BadCredentialsException("Email ou mot de passe incorrect."));
        if (!passwordEncoder.matches(password, user.getPassword())) {
            throw new BadCredentialsException("Email ou mot de passe incorrect.");
        }
        return buildAuthResponse(user);
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalArgumentException("Un compte avec cet email existe déjà.");
        }

        Company company = new Company();
        company.setName(request.getCompanyName());
        company = companyRepository.save(company);

        User user = new User();
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setFirstName(request.getFirstName());
        user.setLastName(request.getLastName());
        user.setPhoneNumber(request.getPhoneNumber());
        user.setCompany(company);
        user.setRole(Role.ADMIN);
        user.setCompanyAdmin(true);
        user = userRepository.save(user);

        return buildAuthResponse(user);
    }

    @Transactional
    public void requestPasswordReset(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
        String token = UUID.randomUUID().toString();
        PasswordResetToken resetToken = new PasswordResetToken(
                token, user, LocalDateTime.now().plusHours(24));
        tokenRepository.save(resetToken);
        sendResetEmail(email, token);
        log.info("Password reset token generated for email: {}", email);
    }

    @Transactional
    public void confirmPasswordReset(String email, String token, String newPassword) {
        PasswordResetToken resetToken = tokenRepository
                .findByTokenAndUsedFalseAndExpiryDateAfter(token, LocalDateTime.now())
                .orElseThrow(() -> new IllegalArgumentException("Token invalide ou expiré."));
        if (!resetToken.getUser().getEmail().equals(email)) {
            throw new IllegalArgumentException("Email ne correspond pas au token.");
        }
        User user = resetToken.getUser();
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
        resetToken.setUsed(true);
        tokenRepository.save(resetToken);
    }

    @Transactional
    public void changePassword(User user, String currentPassword, String newPassword) {
        if (!passwordEncoder.matches(currentPassword, user.getPassword())) {
            throw new BadCredentialsException("Mot de passe actuel incorrect.");
        }
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }

    @Transactional
    public void logout(String refreshToken) {
        // JWT stateless - client should discard token
        // In production, add to blacklist
    }

    public AuthResponse refreshAccessToken(String refreshToken) {
        if (refreshToken == null || !jwtTokenProvider.validateToken(refreshToken)) {
            throw new BadCredentialsException("Token de rafraîchissement invalide ou expiré.");
        }
        Claims claims = jwtTokenProvider.getClaims(refreshToken);
        if (!"refresh".equals(claims.get("type"))) {
            throw new BadCredentialsException("Token de rafraîchissement invalide.");
        }
        Long userId = Long.parseLong(claims.getSubject());
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new BadCredentialsException("Utilisateur introuvable."));
        return buildAuthResponse(user);
    }

    public String encodePassword(String rawPassword) {
        return passwordEncoder.encode(rawPassword);
    }

    public AuthResponse buildAuthResponse(User user) {
        String accessToken = jwtTokenProvider.generateAccessToken(user.getId(), user.getEmail());
        String refreshToken = jwtTokenProvider.generateRefreshToken(user.getId());
        return new AuthResponse(
                UserDto.fromUser(user),
                new AuthResponse.Tokens(accessToken, refreshToken)
        );
    }

    private void sendResetEmail(String email, String token) {
        String resetUrl = appBaseUrl + "/reset-password?token=" + token + "&email=" + email;
        String html = "<h2>Réinitialisation de mot de passe</h2>"
                + "<p>Cliquez sur le lien ci-dessous pour réinitialiser votre mot de passe :</p>"
                + "<p><a href=\"" + resetUrl + "\">Réinitialiser mon mot de passe</a></p>"
                + "<p>Ce lien expire dans 1 heure.</p>"
                + "<p><small>Token: " + token + "</small></p>";
        String text = "Réinitialisation de votre mot de passe\n\n"
                + "Cliquez sur ce lien : " + resetUrl + "\n\n"
                + "Ce lien expire dans 1 heure.";
        brevoEmailService.sendEmail(email, "Réinitialisation de votre mot de passe", html, text);
    }
}
