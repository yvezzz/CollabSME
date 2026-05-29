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

        String responseText;
        if (apiKey == null || apiKey.isEmpty() || apiKey.isBlank()) {
            responseText = fallbackResponse(message);
        } else {
            responseText = callOpenRouter(messages);
            if (responseText.contains("ne répond pas") || responseText.contains("Erreur")) {
                responseText = fallbackResponse(message);
            }
        }

        // Save response
        AIChat assistantChat = new AIChat();
        assistantChat.setUser(user);
        assistantChat.setRole("assistant");
        assistantChat.setContent(responseText);
        assistantChat.setModelUsed(model);
        aiChatRepository.save(assistantChat);

        return responseText;
    }

    private String fallbackResponse(String message) {
        String lower = message.toLowerCase();
        if (lower.contains("tâche") || lower.contains("task") || lower.contains("tache")) {
            return "Pour créer une tâche efficace, je vous suggère de :\n"
                + "1. Définir un titre clair et précis\n"
                + "2. Ajouter une description détaillée avec les critères d'acceptation\n"
                + "3. Fixer une priorité (haute, moyenne, basse)\n"
                + "4. Assigner un responsable\n"
                + "5. Définir une date d'échéance réaliste\n\n"
                + "Souhaitez-vous que je vous aide à rédiger une tâche spécifique ?";
        }
        if (lower.contains("projet") || lower.contains("project")) {
            return "Un bon projet se construit avec :\n"
                + "• Des objectifs clairs et mesurables\n"
                + "• Des tâches bien définies et assignées\n"
                + "• Un suivi régulier des délais et du budget\n"
                + "• Une communication d'équipe fluide\n\n"
                + "CollabSME vous permet de gérer tout cela facilement. Puis-je vous aider sur un aspect particulier ?";
        }
        if (lower.contains("bonjour") || lower.contains("salut") || lower.contains("hello") || lower.contains("hi")) {
            return "Bonjour ! Je suis votre assistant CollabSME AI. Je peux vous aider à :\n"
                + "• Gérer vos projets et tâches\n"
                + "• Analyser les délais et les risques\n"
                + "• Suggérer des améliorations de productivité\n\n"
                + "Comment puis-je vous assister aujourd'hui ?";
        }
        if (lower.contains("délai") || lower.contains("delai") || lower.contains("deadline") || lower.contains("retard") || lower.contains("risque")) {
            return "Pour gérer les délais et risques efficacement :\n"
                + "1. Utilisez le tableau Kanban pour visualiser l'avancement\n"
                + "2. Définissez des jalons intermédiaires\n"
                + "3. Activez les notifications pour être alerté des échéances\n"
                + "4. Mettez à jour régulièrement le statut des tâches\n\n"
                + "CollabSME vous aide à rester maître de vos délais !";
        }
        return "Merci pour votre message ! Je suis actuellement en mode hors ligne, "
            + "mais je peux vous aider avec :\n"
            + "• La gestion de vos projets et tâches\n"
            + "• Le suivi des délais\n"
            + "• L'organisation de votre équipe\n\n"
            + "Pour une assistance plus poussée, reconnectez-vous à Internet ou "
            + "configurez votre clé API OpenRouter dans les paramètres.";
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
        if (apiKey == null || apiKey.isEmpty() || apiKey.isBlank()) {
            return Map.of("description",
                    "Objectif : " + title + "\n\n"
                    + "Cette tâche consiste à réaliser l'objectif décrit ci-dessus. "
                    + "Assurez-vous de définir des critères d'acceptation clairs avant de commencer.",
                    "subtasks", List.of(
                            "Analyser les prérequis pour \"" + title + "\"",
                            "Planifier les étapes de réalisation",
                            "Exécuter les actions définies",
                            "Valider les résultats avec l'équipe"
                    ));
        }

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
        if (apiKey == null || apiKey.isEmpty() || apiKey.isBlank()) {
            return Map.of("summary",
                    "Projet : " + title + "\n"
                    + "Progression : " + String.format("%.0f", pct) + "% (" + done + "/" + total + " tâches terminées)\n\n"
                    + "Le projet est en cours. Continuez à suivre l'avancement via le tableau de bord CollabSME "
                    + "pour vous assurer que les délais sont respectés.");
        }

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
