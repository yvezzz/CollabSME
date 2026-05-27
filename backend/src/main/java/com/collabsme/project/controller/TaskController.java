package com.collabsme.project.controller;

import com.collabsme.project.model.*;
import com.collabsme.project.service.ProjectService;
import com.collabsme.project.service.TaskService;
import com.collabsme.user.User;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
public class TaskController {

    private final ProjectService projectService;
    private final TaskService taskService;

    public TaskController(ProjectService projectService, TaskService taskService) {
        this.projectService = projectService;
        this.taskService = taskService;
    }

    // Tasks within a project
    @GetMapping("/api/projects/{pk:[0-9]+}/tasks/")
    public ResponseEntity<?> listTasks(@AuthenticationPrincipal User user, @PathVariable Long pk,
                                        @RequestParam(required = false) String status,
                                        @RequestParam(defaultValue = "0") int page) {
        Project project = projectService.getProject(pk, user.getCompany());
        Page<Task> tasks = taskService.getTasks(project, status, null, null, page, 20, null);
        if (tasks == null) {
            tasks = taskService.getTasks(project, null, null, null, page, 20, null);
        }
        return ResponseEntity.ok(tasks);
    }

    @PostMapping("/api/projects/{pk:[0-9]+}/tasks/")
    public ResponseEntity<Task> createTask(@AuthenticationPrincipal User user, @PathVariable Long pk,
                                            @RequestBody Task task) {
        Project project = projectService.getProject(pk, user.getCompany());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(taskService.createTask(task, project, user));
    }

    @GetMapping({"/api/projects/{pk:[0-9]+}/tasks/{taskPk:[0-9]+}/", "/api/projects/{pk:[0-9]+}/tasks/{taskPk:[0-9]+}"})
    public ResponseEntity<Task> getTask(@AuthenticationPrincipal User user, @PathVariable Long pk,
                                          @PathVariable Long taskPk) {
        Project project = projectService.getProject(pk, user.getCompany());
        return ResponseEntity.ok(taskService.getTask(project, taskPk));
    }

    @PatchMapping("/api/projects/{pk:[0-9]+}/tasks/{taskPk:[0-9]+}/status/")
    public ResponseEntity<Map<String, String>> updateTaskStatus(@AuthenticationPrincipal User user,
                                                                 @PathVariable Long pk, @PathVariable Long taskPk,
                                                                 @RequestBody Map<String, String> body) {
        Project project = projectService.getProject(pk, user.getCompany());
        Task task = taskService.updateTaskStatus(project, taskPk, body.get("status"));
        return ResponseEntity.ok(Map.of("status", task.getStatus().name()));
    }

    @PatchMapping("/api/projects/{pk:[0-9]+}/tasks/reorder/")
    public ResponseEntity<Map<String, Object>> reorderTask(@AuthenticationPrincipal User user,
                                                            @PathVariable Long pk,
                                                            @RequestBody Map<String, Object> body) {
        Project project = projectService.getProject(pk, user.getCompany());
        Task task = taskService.reorderTask(project,
                body.get("task_id").toString(),
                body.get("new_status").toString(),
                (int) body.get("new_order"));
        return ResponseEntity.ok(Map.of("status", task.getStatus().name(), "order", task.getOrder()));
    }

    // My tasks
    @GetMapping("/api/tasks/my-tasks/")
    public ResponseEntity<?> myTasks(@AuthenticationPrincipal User user,
                                      @RequestParam(defaultValue = "0") int page) {
        return ResponseEntity.ok(taskService.getMyTasks(user, page, 20));
    }

    // Activity
    @GetMapping("/api/tasks/activity/")
    public ResponseEntity<?> taskActivity(@AuthenticationPrincipal User user,
                                           @RequestParam(defaultValue = "50") int limit) {
        return ResponseEntity.ok(taskService.getActivity(user.getCompany(), limit));
    }
}
