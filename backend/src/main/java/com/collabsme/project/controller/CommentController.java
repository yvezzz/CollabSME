package com.collabsme.project.controller;

import com.collabsme.project.model.Comment;
import com.collabsme.project.service.ProjectService;
import com.collabsme.project.service.TaskService;
import com.collabsme.user.User;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/projects/{pk:[0-9]+}/tasks/{taskPk:[0-9]+}/comments")
public class CommentController {

    private final ProjectService projectService;
    private final TaskService taskService;

    public CommentController(ProjectService projectService, TaskService taskService) {
        this.projectService = projectService;
        this.taskService = taskService;
    }

    @PostMapping({"/", ""})
    public ResponseEntity<Comment> addComment(@AuthenticationPrincipal User user,
                                               @PathVariable Long pk, @PathVariable Long taskPk,
                                               @RequestBody Map<String, String> body) {
        var project = projectService.getProject(pk, user.getCompany());
        var comment = taskService.addComment(project, taskPk, body.get("content"),
                body.get("mentions"), user);
        return ResponseEntity.status(HttpStatus.CREATED).body(comment);
    }
}
