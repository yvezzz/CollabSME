package com.collabsme.project.controller;

import com.collabsme.project.model.ProjectTemplate;
import com.collabsme.project.service.TemplateService;
import com.collabsme.user.User;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/projects/templates")
public class TemplateController {

    private final TemplateService templateService;

    public TemplateController(TemplateService templateService) {
        this.templateService = templateService;
    }

    @GetMapping({"/", ""})
    public ResponseEntity<?> listTemplates(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(templateService.getTemplates(user.getCompany()));
    }

    @PostMapping({"/", ""})
    public ResponseEntity<ProjectTemplate> createTemplate(@AuthenticationPrincipal User user,
                                                           @RequestBody ProjectTemplate template) {
        if (user.getRole() == null || !user.getRole().name().equals("ADMIN")) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(null);
        }
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(templateService.createTemplate(template, user.getCompany()));
    }

    @PostMapping("/create-from-template/")
    public ResponseEntity<?> createFromTemplate(@AuthenticationPrincipal User user,
                                                 @RequestBody Map<String, String> body) {
        Long templateId = Long.parseLong(body.get("template_id"));
        String title = body.get("title");
        if (templateId == null || title == null || title.isEmpty()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "template_id et title requis."));
        }
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(templateService.createProjectFromTemplate(templateId, title, user.getCompany(), user));
    }
}
