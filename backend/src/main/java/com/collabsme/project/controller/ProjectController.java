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

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/projects")
public class ProjectController {

    private final ProjectService projectService;
    private final TaskService taskService;

    public ProjectController(ProjectService projectService, TaskService taskService) {
        this.projectService = projectService;
        this.taskService = taskService;
    }

    // Dashboard & Global
    @GetMapping("/dashboard/stats/")
    public ResponseEntity<Map<String, Object>> dashboardStats(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(projectService.getDashboardStats(user.getCompany()));
    }

    @GetMapping("/reports/")
    public ResponseEntity<Map<String, Object>> reports(@AuthenticationPrincipal User user) {
        return ResponseEntity.ok(projectService.getReports(user.getCompany()));
    }

    @GetMapping("/search/")
    public ResponseEntity<Map<String, Object>> search(@AuthenticationPrincipal User user,
                                                       @RequestParam(defaultValue = "") String q) {
        return ResponseEntity.ok(projectService.globalSearch(user.getCompany(), q));
    }

    @GetMapping("/calendar/")
    public ResponseEntity<List<Map<String, Object>>> calendar(@AuthenticationPrincipal User user,
                                                               @RequestParam(required = false) Integer month,
                                                               @RequestParam(required = false) Integer year) {
        return ResponseEntity.ok(projectService.getCalendarTasks(user.getCompany(), month, year));
    }

    // Project CRUD
    @GetMapping({"/", ""})
    public ResponseEntity<?> listProjects(@AuthenticationPrincipal User user,
                                           @RequestParam(required = false) String status,
                                           @RequestParam(defaultValue = "0") int page) {
        List<Project> projects = projectService.getProjectsByCompany(user.getCompany());
        return ResponseEntity.ok(projects);
    }

    @PostMapping({"/", ""})
    public ResponseEntity<Project> createProject(@AuthenticationPrincipal User user,
                                                   @RequestBody Project project) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(projectService.createProject(project, user));
    }

    @GetMapping({"/{pk:[0-9]+}/", "/{pk:[0-9]+}"})
    public ResponseEntity<Project> getProject(@AuthenticationPrincipal User user,
                                                 @PathVariable Long pk) {
        return ResponseEntity.ok(projectService.getProject(pk, user.getCompany()));
    }

    @PatchMapping({"/{pk:[0-9]+}/", "/{pk:[0-9]+}"})
    public ResponseEntity<Project> updateProject(@AuthenticationPrincipal User user,
                                                    @PathVariable Long pk,
                                                    @RequestBody Project project) {
        return ResponseEntity.ok(projectService.updateProject(pk, project, user));
    }

    @DeleteMapping({"/{pk:[0-9]+}/", "/{pk:[0-9]+}"})
    public ResponseEntity<Void> deleteProject(@AuthenticationPrincipal User user,
                                                @PathVariable Long pk) {
        projectService.deleteProject(pk, user);
        return ResponseEntity.noContent().build();
    }

    // Project status actions
    @PostMapping("/{pk:[0-9]+}/{action}/")
    public ResponseEntity<Map<String, String>> updateStatus(@AuthenticationPrincipal User user,
                                                              @PathVariable Long pk,
                                                              @PathVariable String action) {
        Project project = projectService.updateStatus(pk, action, user);
        return ResponseEntity.ok(Map.of("status", project.getStatus().name()));
    }

    // Stats
    @GetMapping("/{pk:[0-9]+}/stats/")
    public ResponseEntity<Map<String, Object>> projectStats(@AuthenticationPrincipal User user,
                                                              @PathVariable Long pk) {
        Project project = projectService.getProject(pk, user.getCompany());
        return ResponseEntity.ok(projectService.getProjectStats(project));
    }

    // Workload
    @GetMapping("/{pk:[0-9]+}/workload/")
    public ResponseEntity<List<Map<String, Object>>> workload(@AuthenticationPrincipal User user,
                                                               @PathVariable Long pk) {
        Project project = projectService.getProject(pk, user.getCompany());
        return ResponseEntity.ok(projectService.getWorkload(project));
    }
}
