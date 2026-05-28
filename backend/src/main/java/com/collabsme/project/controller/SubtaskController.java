package com.collabsme.project.controller;

import com.collabsme.project.model.ChecklistItem;
import com.collabsme.project.service.ProjectService;
import com.collabsme.project.service.TaskService;
import com.collabsme.user.User;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
public class SubtaskController {

    private final ProjectService projectService;
    private final TaskService taskService;

    public SubtaskController(ProjectService projectService, TaskService taskService) {
        this.projectService = projectService;
        this.taskService = taskService;
    }

    @PostMapping("/api/projects/{pk:[0-9]+}/tasks/{taskPk:[0-9]+}/subtasks/")
    public ResponseEntity<ChecklistItem> create(@AuthenticationPrincipal User user,
                                                 @PathVariable Long pk, @PathVariable Long taskPk,
                                                 @RequestBody Map<String, String> body) {
        var project = projectService.getProject(pk, user.getCompany());
        var item = taskService.addChecklistItem(project, taskPk, body.get("title"), user);
        return ResponseEntity.status(HttpStatus.CREATED).body(item);
    }

    @PatchMapping("/api/projects/{pk:[0-9]+}/tasks/{taskPk:[0-9]+}/subtasks/{subtaskPk:[0-9]+}/")
    public ResponseEntity<ChecklistItem> update(@AuthenticationPrincipal User user,
                                                 @PathVariable Long pk, @PathVariable Long taskPk,
                                                 @PathVariable Long subtaskPk,
                                                 @RequestBody Map<String, Object> body) {
        var project = projectService.getProject(pk, user.getCompany());
        boolean completed = body.containsKey("is_completed") && (boolean) body.get("is_completed");
        String title = (String) body.get("title");
        var item = taskService.updateChecklistItem(project, taskPk, subtaskPk, completed, title, user);
        return ResponseEntity.ok(item);
    }
}
