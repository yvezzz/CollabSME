package com.collabsme.ai;

import com.collabsme.user.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.*;

import java.util.*;

@Service
public class AIService {

    private static final Logger log = LoggerFactory.getLogger(AIService.class);
    private static final String SYSTEM_PROMPT = "Tu es un assistant IA spécialisé en gestion de projet. Tu aides les équipes à organiser leur travail, suggérer des tâches, et améliorer leur productivité. Réponds en français.";

    private final AIChatRepository aiChatRepository;
    private final RestTemplate restTemplate;

    @Value("${app.openrouter.api-key}")
    private String apiKey;

    @Value("${app.openrouter.model}")
    private String model;

    @Value("${app.openrouter.url}")
    private String url;

    public AIService(AIChatRepository aiChatRepository) {
        this.aiChatRepository = aiChatRepository;
        this.restTemplate = new RestTemplate();
    }

    public String chat(User user, String message) {
        if (apiKey == null || apiKey.isEmpty()) {
            return "Clé API OpenRouter non configurée.";
        }

        // Save user message
        AIChat userChat = new AIChat();
        userChat.setUser(user);
        userChat.setRole("user");
        userChat.setContent(message);
        userChat.setModelUsed(model);
        aiChatRepository.save(userChat);

        // Build conversation
        List<AIChat> history = aiChatRepository.findTop20ByUserOrderByCreatedAtDesc(user);
        Collections.reverse(history);

        List<Map<String, String>> messages = new ArrayList<>();
        messages.add(Map.of("role", "system", "content", SYSTEM_PROMPT));
        for (AIChat chat : history) {
            messages.add(Map.of("role", chat.getRole(), "content", chat.getContent()));
        }

        // Call OpenRouter
        String responseText = callOpenRouter(messages);

        // Save response
        AIChat assistantChat = new AIChat();
        assistantChat.setUser(user);
        assistantChat.setRole("assistant");
        assistantChat.setContent(responseText);
        assistantChat.setModelUsed(model);
        aiChatRepository.save(assistantChat);

        return responseText;
    }

    private String callOpenRouter(List<Map<String, String>> messages) {
        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.set("Authorization", "Bearer " + apiKey);
            headers.set("HTTP-Referer", "https://koda.app");

            Map<String, Object> request = new LinkedHashMap<>();
            request.put("model", model);
            request.put("messages", messages);
            request.put("max_tokens", 1024);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(request, headers);
            ResponseEntity<Map> response = restTemplate.postForEntity(url, entity, Map.class);

            if (response.getBody() != null && response.getBody().containsKey("choices")) {
                List<Map<String, Object>> choices = (List<Map<String, Object>>) response.getBody().get("choices");
                if (!choices.isEmpty()) {
                    Map<String, Object> choice = choices.get(0);
                    Map<String, String> message = (Map<String, String>) choice.get("message");
                    return message.get("content");
                }
            }
            return "Erreur du service IA.";
        } catch (Exception e) {
            log.error("OpenRouter call failed", e);
            return "Le service IA ne répond pas.";
        }
    }

    public Map<String, Object> generateTask(String title) {
        List<Map<String, String>> messages = new ArrayList<>();
        messages.add(Map.of("role", "system", "content", SYSTEM_PROMPT));
        messages.add(Map.of("role", "user", "content",
                "Génère une description détaillée et des sous-tâches pour la tâche suivante: \""
                + title + "\". Réponds au format JSON avec \"description\" et \"subtasks\" (liste de strings)."));

        String response = callOpenRouter(messages);
        try {
            if (response.startsWith("{") || response.startsWith("```")) {
                String json = response.replaceAll("```json\\s*|```\\s*", "").trim();
                com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
                return mapper.readValue(json, java.util.LinkedHashMap.class);
            }
        } catch (Exception e) {
            // fall through
        }
        return Map.of("description", response, "subtasks", Collections.emptyList());
    }

    public Map<String, String> summarizeProject(String title, long total, long done, double pct) {
        List<Map<String, String>> messages = new ArrayList<>();
        messages.add(Map.of("role", "system", "content", SYSTEM_PROMPT));
        messages.add(Map.of("role", "user", "content",
                "Résume le projet \"" + title + "\" avec " + total + " tâches dont "
                + done + " terminées (" + String.format("%.0f", pct) + "%). "
                + "Donne un résumé concis en français."));

        String response = callOpenRouter(messages);
        return Map.of("summary", response);
    }
}
