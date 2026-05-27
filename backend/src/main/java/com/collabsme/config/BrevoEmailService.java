package com.collabsme.config;

import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

@Service
public class BrevoEmailService {

    private static final Logger log = LoggerFactory.getLogger(BrevoEmailService.class);
    private static final String BREVO_API_URL = "https://api.brevo.com/v3/smtp/email";

    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${BREVO_API_KEY:}")
    private String apiKey;

    private boolean enabled;

    @PostConstruct
    public void init() {
        enabled = apiKey != null && !apiKey.isEmpty();
        if (enabled) {
            restTemplate.getInterceptors().add((req, body, exec) -> {
                req.getHeaders().set("api-key", apiKey);
                req.getHeaders().setContentType(MediaType.APPLICATION_JSON);
                return exec.execute(req, body);
            });
            log.info("Brevo email service enabled");
        } else {
            log.info("Brevo email service disabled (no API key)");
        }
    }

    public boolean isEnabled() {
        return enabled;
    }

    public void sendEmail(String to, String subject, String htmlContent, String textContent) {
        if (!enabled) {
            log.warn("Brevo non configuré, email non envoyé à {}", to);
            return;
        }
        try {
            Map<String, Object> payload = Map.of(
                "sender", Map.of("name", "CollabSME", "email", "tambat.yvan18@gmail.com"),
                "to", List.of(Map.of("email", to)),
                "subject", subject,
                "htmlContent", htmlContent,
                "textContent", textContent
            );
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(payload);
            ResponseEntity<Map> response = restTemplate.postForEntity(BREVO_API_URL, entity, Map.class);
            if (response.getStatusCode().is2xxSuccessful()) {
                log.info("Email envoyé à {} via Brevo (messageId: {})", to,
                    response.getBody() != null ? response.getBody().get("messageId") : "?");
            } else {
                log.error("Échec envoi Brevo: {} - {}", response.getStatusCode(), response.getBody());
            }
        } catch (Exception e) {
            log.error("Erreur lors de l'envoi Brevo à {}", to, e);
        }
    }
}
