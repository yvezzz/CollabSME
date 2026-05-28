package com.collabsme.invitation;

import com.collabsme.auth.AuthService;
import com.collabsme.auth.dto.AuthResponse;
import com.collabsme.auth.dto.RegisterRequest;
import com.collabsme.config.BrevoEmailService;
import com.collabsme.notification.NotificationService;
import com.collabsme.user.Role;
import com.collabsme.user.User;
import com.collabsme.user.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/invitations")
public class InvitationController {

    private static final Logger log = LoggerFactory.getLogger(InvitationController.class);

    private final InvitationRepository invitationRepository;
    private final UserRepository userRepository;
    private final AuthService authService;
    private final BrevoEmailService brevoEmailService;
    private final NotificationService notificationService;

    public InvitationController(InvitationRepository invitationRepository,
                                UserRepository userRepository,
                                AuthService authService,
                                BrevoEmailService brevoEmailService,
                                NotificationService notificationService) {
        this.invitationRepository = invitationRepository;
        this.userRepository = userRepository;
        this.authService = authService;
        this.brevoEmailService = brevoEmailService;
        this.notificationService = notificationService;
    }

    @GetMapping({"/", ""})
    public ResponseEntity<?> list(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(
                invitationRepository.findByCompanyOrderByCreatedAtDesc(user.getCompany()));
    }

    @PostMapping({"/", ""})
    public ResponseEntity<?> create(@AuthenticationPrincipal User user,
                                     @RequestBody Map<String, String> body) {
        if (!user.isCompanyAdmin()) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(Map.of("error", "Action non autorisée."));
        }
        String email = body.get("email");
        String roleStr = body.getOrDefault("role", "MEMBER");

        if (invitationRepository.existsByCompanyAndEmail(user.getCompany(), email)) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Une invitation existe déjà pour cet email."));
        }

        Invitation invitation = new Invitation();
        invitation.setCompany(user.getCompany());
        invitation.setEmail(email);
        try {
            invitation.setRole(Role.valueOf(roleStr));
        } catch (IllegalArgumentException e) {
            invitation.setRole(Role.MEMBER);
        }
        invitation.setInvitedBy(user);
        invitation = invitationRepository.save(invitation);

        // Send email
        String companyName = user.getCompany().getName();
        String inviterName = user.getFirstName() + " " + user.getLastName();
        String html = "<h2>Invitation à rejoindre " + companyName + "</h2>"
                + "<p>" + inviterName + " vous a invité à rejoindre " + companyName + ".</p>"
                + "<p><a href=\"https://koda.app/invitation?token=" + invitation.getToken() + "\">Accepter l'invitation</a></p>"
                + "<p>Token: " + invitation.getToken() + "</p>";
        String text = "Invitation à rejoindre " + companyName
                + "\n\n" + inviterName + " vous a invité à rejoindre " + companyName + "."
                + "\n\nToken: " + invitation.getToken();
        brevoEmailService.sendEmail(email, "Invitation à rejoindre " + companyName, html, text);

        return ResponseEntity.status(HttpStatus.CREATED).body(invitation);
    }

    @DeleteMapping({"/{pk}/", "/{pk}"})
    public ResponseEntity<Void> cancel(@AuthenticationPrincipal User user, @PathVariable Long pk) {
        invitationRepository.findById(pk)
                .filter(i -> i.getCompany().getId().equals(user.getCompany().getId()))
                .ifPresent(invitationRepository::delete);
        return ResponseEntity.noContent().build();
    }

    @GetMapping({"/validate/{token}/", "/validate/{token}"})
    public ResponseEntity<?> validate(@PathVariable UUID token) {
        Invitation invitation = invitationRepository.findByToken(token)
                .filter(i -> i.getStatus() == InvitationStatus.PENDING)
                .orElseThrow(() -> new RuntimeException("Lien d'invitation invalide ou expiré."));
        return ResponseEntity.ok(Map.of(
                "email", invitation.getEmail(),
                "company", invitation.getCompany().getName(),
                "role", invitation.getRole().name(),
                "token", invitation.getToken().toString()
        ));
    }

    @PostMapping({"/accept/{token}/", "/accept/{token}"})
    public ResponseEntity<?> accept(@PathVariable UUID token, @RequestBody RegisterRequest request) {
        Invitation invitation = invitationRepository.findByToken(token)
                .filter(i -> i.getStatus() == InvitationStatus.PENDING)
                .orElseThrow(() -> new RuntimeException("Lien d'invitation invalide ou expiré."));

        request.setEmail(invitation.getEmail());
        request.setCompanyName(invitation.getCompany().getName());
        AuthResponse authResponse = authService.register(request);

        User user = userRepository.findByEmail(invitation.getEmail()).orElseThrow();
        user.setCompany(invitation.getCompany());
        user.setRole(invitation.getRole());
        user.setCompanyAdmin(invitation.getRole() == Role.ADMIN);
        userRepository.save(user);

        invitation.setStatus(InvitationStatus.ACCEPTED);
        invitationRepository.save(invitation);

        if (invitation.getInvitedBy() != null) {
            notificationService.send(invitation.getInvitedBy(), "Invitation acceptée",
                    user.getFirstName() + " " + user.getLastName() + " a accepté votre invitation",
                    "INVITATION_ACCEPTED", user.getId().toString());
        }

        return ResponseEntity.status(HttpStatus.CREATED).body(authResponse);
    }

    @PostMapping({"/decline/{token}/", "/decline/{token}"})
    public ResponseEntity<Map<String, String>> decline(@PathVariable UUID token) {
        invitationRepository.findByToken(token)
                .filter(i -> i.getStatus() == InvitationStatus.PENDING)
                .ifPresent(i -> {
                    i.setStatus(InvitationStatus.DECLINED);
                    invitationRepository.save(i);
                    if (i.getInvitedBy() != null) {
                        notificationService.send(i.getInvitedBy(), "Invitation refusée",
                                i.getEmail() + " a refusé votre invitation",
                                "INVITATION_DECLINED", i.getId().toString());
                    }
                });
        return ResponseEntity.ok(Map.of("message", "Invitation refusée."));
    }
}
