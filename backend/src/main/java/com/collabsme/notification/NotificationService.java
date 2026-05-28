package com.collabsme.notification;

import com.collabsme.config.NotificationWebSocketHandler;
import com.collabsme.user.User;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);
    private final NotificationRepository notificationRepository;
    private final NotificationWebSocketHandler webSocketHandler;
    private final ObjectMapper objectMapper;

    public NotificationService(NotificationRepository notificationRepository,
                               NotificationWebSocketHandler webSocketHandler,
                               ObjectMapper objectMapper) {
        this.notificationRepository = notificationRepository;
        this.webSocketHandler = webSocketHandler;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public Notification send(User user, String title, String message,
                             String notificationType, String relatedId) {
        Notification notification = new Notification();
        notification.setUser(user);
        notification.setTitle(title);
        notification.setMessage(message);
        notification.setNotificationType(notificationType);
        notification.setRelatedId(relatedId);
        notification = notificationRepository.save(notification);

        broadcast(notification);
        return notification;
    }

    private void broadcast(Notification notification) {
        try {
            Map<String, Object> payload = Map.of(
                    "type", "notification",
                    "notification", Map.of(
                            "id", notification.getId(),
                            "title", notification.getTitle(),
                            "message", notification.getMessage(),
                            "notification_type", notification.getNotificationType(),
                            "is_read", notification.isRead(),
                            "related_id", notification.getRelatedId() != null ? notification.getRelatedId() : "",
                            "created_at", notification.getCreatedAt() != null ? notification.getCreatedAt().toString() : ""
                    )
            );
            String json = objectMapper.writeValueAsString(payload);
            webSocketHandler.sendToUser(notification.getUser().getId(), json);
        } catch (JsonProcessingException e) {
            log.warn("Failed to serialize notification for WS: {}", e.getMessage());
        }
    }
}
