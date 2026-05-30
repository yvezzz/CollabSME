package com.collabsme.project.controller;

import com.collabsme.project.model.*;
import com.collabsme.project.service.ProjectService;
import com.collabsme.project.service.TaskService;
import com.collabsme.company.CompanyRepository;
import com.collabsme.user.User;
import com.collabsme.user.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.*;
import java.util.stream.Collectors;

@RestController
public class TaskController {

    private final ProjectService projectService;
    private final TaskService taskService;
    private final CompanyRepository companyRepository;
    private final UserRepository userRepository;

    public TaskController(ProjectService projectService, TaskService taskService,
                          CompanyRepository companyRepository, UserRepository userRepository) {
        this.projectService = projectService;
        this.taskService = taskService;
        this.companyRepository = companyRepository;
        this.userRepository = userRepository;
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
        List<Map<String, Object>> items = tasks.getContent().stream().map(this::toTaskMap).collect(Collectors.toList());
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("content", items);
        result.put("totalElements", tasks.getTotalElements());
        result.put("totalPages", tasks.getTotalPages());
        result.put("number", tasks.getNumber());
        return ResponseEntity.ok(result);
    }

    @PostMapping("/api/projects/{pk:[0-9]+}/tasks/")
    public ResponseEntity<Task> createTask(@AuthenticationPrincipal User user, @PathVariable Long pk,
                                            @RequestBody Map<String, Object> body) {
        Project project = projectService.getProject(pk, user.getCompany());
        Task task = new Task();
        task.setTitle((String) body.get("title"));
        task.setDescription((String) body.getOrDefault("description", ""));
        if (body.containsKey("status")) {
            try { task.setStatus(TaskStatus.valueOf((String) body.get("status"))); } catch (Exception ignored) {}
        }
        if (body.containsKey("priority")) {
            try { task.setPriority(Priority.valueOf((String) body.get("priority"))); } catch (Exception ignored) {}
        }
        if (body.containsKey("due_date")) {
            try { task.setDueDate(java.time.LocalDate.parse((String) body.get("due_date"))); } catch (Exception ignored) {}
        }
        if (body.containsKey("assigned_to")) {
            try {
                Long assignedId = Long.valueOf(body.get("assigned_to").toString());
                userRepository.findById(assignedId).ifPresent(task::setAssignedTo);
            } catch (Exception ignored) {}
        }
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(taskService.createTask(task, project, user));
    }

    @GetMapping({"/api/projects/{pk:[0-9]+}/tasks/{taskPk:[0-9]+}/", "/api/projects/{pk:[0-9]+}/tasks/{taskPk:[0-9]+}"})
    public ResponseEntity<Map<String, Object>> getTask(@AuthenticationPrincipal User user, @PathVariable Long pk,
                                                        @PathVariable Long taskPk) {
        Project project = projectService.getProject(pk, user.getCompany());
        return ResponseEntity.ok(toTaskMap(taskService.getTask(project, taskPk)));
    }

    @PatchMapping("/api/projects/{pk:[0-9]+}/tasks/{taskPk:[0-9]+}/status/")
    public ResponseEntity<Map<String, String>> updateTaskStatus(@AuthenticationPrincipal User user,
                                                                 @PathVariable Long pk, @PathVariable Long taskPk,
                                                                 @RequestBody Map<String, String> body) {
        Project project = projectService.getProject(pk, user.getCompany());
        Task task = taskService.updateTaskStatus(project, taskPk, body.get("status"), user);
        return ResponseEntity.ok(Map.of("status", task.getStatus().name()));
    }

    // Full task update (PUT) — title, description, priority, assigned_to, due_date, status
    @PutMapping("/api/projects/{pk:[0-9]+}/tasks/{taskPk:[0-9]+}/")
    public ResponseEntity<Map<String, Object>> updateTask(@AuthenticationPrincipal User user,
                                                           @PathVariable Long pk, @PathVariable Long taskPk,
                                                           @RequestBody Map<String, Object> body) {
        Project project = projectService.getProject(pk, user.getCompany());
        Task task = taskService.updateTask(project, taskPk, body, user);
        return ResponseEntity.ok(toTaskMap(task));
    }

    // Delete task
    @DeleteMapping("/api/projects/{pk:[0-9]+}/tasks/{taskPk:[0-9]+}/")
    public ResponseEntity<Map<String, String>> deleteTask(@AuthenticationPrincipal User user,
                                                           @PathVariable Long pk, @PathVariable Long taskPk) {
        Project project = projectService.getProject(pk, user.getCompany());
        taskService.deleteTask(project, taskPk, user);
        return ResponseEntity.ok(Map.of("message", "Tâche supprimée"));
    }

    @PatchMapping("/api/projects/{pk:[0-9]+}/tasks/reorder/")
    public ResponseEntity<Map<String, Object>> reorderTask(@AuthenticationPrincipal User user,
                                                            @PathVariable Long pk,
                                                            @RequestBody Map<String, Object> body) {
        Project project = projectService.getProject(pk, user.getCompany());
        Task task = taskService.reorderTask(project,
                body.get("task_id").toString(),
                body.get("new_status").toString(),
                (int) body.get("new_order"), user);
        return ResponseEntity.ok(Map.of("status", task.getStatus().name(), "order", task.getOrder()));
    }

    // My tasks
    @GetMapping("/api/tasks/my-tasks/")
    public ResponseEntity<?> myTasks(@AuthenticationPrincipal User user,
                                      @RequestParam(defaultValue = "0") int page) {
        var tasks = taskService.getMyTasks(user, page, 20);
        var list = tasks.stream().map(t -> {
            Map<String, Object> m = toTaskMap(t);
            m.put("project_title", t.getProject().getTitle());
            return m;
        }).toList();
        return ResponseEntity.ok(list);
    }

    // Activity
    @GetMapping("/api/tasks/activity/")
    public ResponseEntity<?> taskActivity(@AuthenticationPrincipal User user,
                                           @RequestParam(defaultValue = "50") int limit) {
        if (user.getCompany() == null || user.getCompany().getId() == null) {
            return ResponseEntity.ok(Collections.emptyList());
        }
        var company = companyRepository.findById(user.getCompany().getId())
                .orElse(null);
        if (company == null) return ResponseEntity.ok(Collections.emptyList());
        return ResponseEntity.ok(taskService.getActivity(company, limit));
    }

    private Map<String, Object> toTaskMap(Task task) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", task.getId());
        m.put("title", task.getTitle());
        m.put("description", task.getDescription());
        m.put("status", task.getStatus() != null ? task.getStatus().name() : null);
        m.put("priority", task.getPriority() != null ? task.getPriority().name() : null);
        m.put("created_at", task.getCreatedAt() != null ? task.getCreatedAt().toString() : null);
        m.put("due_date", task.getDueDate() != null ? task.getDueDate().toString() : null);
        m.put("start_date", task.getStartDate() != null ? task.getStartDate().toString() : null);
        m.put("estimated_hours", task.getEstimatedHours());
        m.put("actual_hours", task.getActualHours());
        m.put("order", task.getOrder());
        m.put("project", task.getProject().getId());
        if (task.getAssignedTo() != null) {
            m.put("assigned_to", task.getAssignedTo().getId());
            m.put("assigned_to_name", task.getAssignedTo().getFirstName() + " " + task.getAssignedTo().getLastName());
        }
        // Parse tags from JSON string to List
        ObjectMapper mapper = new ObjectMapper();
        try {
            if (task.getTags() != null && !task.getTags().isEmpty()) {
                m.put("tags", mapper.readValue(task.getTags(), List.class));
            } else {
                m.put("tags", new ArrayList<>());
            }
        } catch (Exception e) {
            m.put("tags", task.getTags());
        }
        try {
            if (task.getCustomFields() != null && !task.getCustomFields().isEmpty()) {
                m.put("custom_fields", mapper.readValue(task.getCustomFields(), Map.class));
            } else {
                m.put("custom_fields", new HashMap<>());
            }
        } catch (Exception e) {
            m.put("custom_fields", task.getCustomFields());
        }
        return m;
    }
}
