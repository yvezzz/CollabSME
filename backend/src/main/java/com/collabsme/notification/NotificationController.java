package com.collabsme.notification;

import com.collabsme.user.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationRepository notificationRepository;

    public NotificationController(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    @GetMapping({"/", ""})
    public ResponseEntity<Page<Notification>> list(@AuthenticationPrincipal User user,
                                                    @RequestParam(defaultValue = "0") int page) {
        return ResponseEntity.ok(
                notificationRepository.findByUserOrderByCreatedAtDesc(user, PageRequest.of(page, 20)));
    }

    @GetMapping("/unread_count/")
    public ResponseEntity<Map<String, Long>> unreadCount(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(Map.of("unread_count",
                notificationRepository.countByUserAndIsReadFalse(user)));
    }

    @PostMapping("/{pk}/mark_as_read/")
    public ResponseEntity<Notification> markAsRead(@AuthenticationPrincipal User user,
                                                    @PathVariable Long pk) {
        Notification notification = notificationRepository.findById(pk)
                .filter(n -> n.getUser().getId().equals(user.getId()))
                .orElseThrow(() -> new RuntimeException("Notification introuvable."));
        notification.setRead(true);
        return ResponseEntity.ok(notificationRepository.save(notification));
    }

    @PostMapping("/mark_all_as_read/")
    public ResponseEntity<Map<String, Integer>> markAllAsRead(@AuthenticationPrincipal User user) {
        Page<Notification> page = notificationRepository
                .findByUserOrderByCreatedAtDesc(user, PageRequest.of(0, Integer.MAX_VALUE));
        int updated = 0;
        for (Notification n : page.getContent()) {
            if (!n.isRead()) {
                n.setRead(true);
                notificationRepository.save(n);
                updated++;
            }
        }
        return ResponseEntity.ok(Map.of("updated", updated));
    }
}
