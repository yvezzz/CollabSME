package com.collabsme.ai;

import com.collabsme.exception.ResourceNotFoundException;
import com.collabsme.project.model.Project;
import com.collabsme.project.model.TaskStatus;
import com.collabsme.project.repository.ProjectRepository;
import com.collabsme.project.repository.TaskRepository;
import com.collabsme.user.User;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/ai")
public class AIController {

    private final AIService aiService;
    private final AIChatRepository aiChatRepository;
    private final ProjectRepository projectRepository;
    private final TaskRepository taskRepository;

    public AIController(AIService aiService, AIChatRepository aiChatRepository,
                        ProjectRepository projectRepository, TaskRepository taskRepository) {
        this.aiService = aiService;
        this.aiChatRepository = aiChatRepository;
        this.projectRepository = projectRepository;
        this.taskRepository = taskRepository;
    }

    @PostMapping("/chat/")
    public ResponseEntity<Map<String, String>> chat(@AuthenticationPrincipal User user,
                                                     @RequestBody Map<String, String> body) {
        String message = body.get("message");
        if (message == null || message.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Message requis."));
        }
        String response = aiService.chat(user, message);
        return ResponseEntity.ok(Map.of("response", response));
    }

    @GetMapping("/chat/")
    public ResponseEntity<?> history(@AuthenticationPrincipal User user,
                                      @RequestParam(defaultValue = "50") int limit) {
        var chats = aiChatRepository.findTop20ByUserOrderByCreatedAtDesc(user);
        java.util.Collections.reverse(chats);
        return ResponseEntity.ok(chats);
    }

    @DeleteMapping("/chat/")
    public ResponseEntity<Void> clear(@AuthenticationPrincipal User user) {
        aiChatRepository.deleteByUser(user);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/generate-task/")
    public ResponseEntity<?> generateTask(@AuthenticationPrincipal User user,
                                           @RequestBody Map<String, String> body) {
        String title = body.get("title");
        if (title == null || title.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Titre requis."));
        }
        return ResponseEntity.ok(aiService.generateTask(title));
    }

    @PostMapping("/summarize-project/")
    public ResponseEntity<?> summarizeProject(@AuthenticationPrincipal User user,
                                               @RequestBody Map<String, String> body) {
        String projectId = body.get("project_id");
        if (projectId == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "project_id requis."));
        }
        Project project = projectRepository.findById(Long.parseLong(projectId))
                .orElseThrow(() -> new ResourceNotFoundException("Projet introuvable."));
        if (!project.getCompany().getId().equals(user.getCompany().getId())) {
            return ResponseEntity.badRequest().body(Map.of("error", "Projet introuvable."));
        }
        long total = taskRepository.countByProject(project);
        long done = taskRepository.countByProjectAndStatus(project, TaskStatus.DONE);
        double pct = total > 0 ? (double) done / total * 100 : 0;
        return ResponseEntity.ok(aiService.summarizeProject(project.getTitle(), total, done, pct));
    }
}
