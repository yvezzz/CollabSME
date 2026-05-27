package com.collabsme.project.controller;

import com.collabsme.project.model.Attachment;
import com.collabsme.project.service.ProjectService;
import com.collabsme.project.service.TaskService;
import com.collabsme.user.User;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Map;

@RestController
@RequestMapping("/api/projects/{pk:[0-9]+}/tasks/{taskPk:[0-9]+}/attachments")
public class AttachmentController {

    private final ProjectService projectService;
    private final TaskService taskService;

    @Value("${app.upload.dir:./uploads}")
    private String uploadDir;

    public AttachmentController(ProjectService projectService, TaskService taskService) {
        this.projectService = projectService;
        this.taskService = taskService;
    }

    @PostMapping({"/", ""})
    public ResponseEntity<?> upload(@AuthenticationPrincipal User user,
                                     @PathVariable Long pk, @PathVariable Long taskPk,
                                     @RequestParam("file") MultipartFile file) throws IOException {
        if (file.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Fichier requis."));
        }
        var project = projectService.getProject(pk, user.getCompany());
        var attachment = taskService.uploadAttachment(project, taskPk, file, uploadDir, user);
        return ResponseEntity.status(HttpStatus.CREATED).body(attachment);
    }
}
