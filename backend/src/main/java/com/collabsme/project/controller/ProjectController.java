package com.collabsme.project.controller;

import com.collabsme.project.model.*;
import com.collabsme.project.repository.ProjectMemberRepository;
import com.collabsme.project.repository.TaskRepository;
import com.collabsme.project.service.ProjectService;
import com.collabsme.project.service.TaskService;
import com.collabsme.user.User;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.*;

@RestController
@RequestMapping("/api/projects")
public class ProjectController {

    private final ProjectService projectService;
    private final TaskService taskService;
    private final TaskRepository taskRepository;
    private final ProjectMemberRepository memberRepository;
    private final ObjectMapper objectMapper;

    public ProjectController(ProjectService projectService, TaskService taskService,
                             TaskRepository taskRepository, ProjectMemberRepository memberRepository,
                             ObjectMapper objectMapper) {
        this.projectService = projectService;
        this.taskService = taskService;
        this.taskRepository = taskRepository;
        this.memberRepository = memberRepository;
        this.objectMapper = objectMapper;
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

    @GetMapping("/reports/export/csv/")
    public ResponseEntity<byte[]> exportCsv(@AuthenticationPrincipal User user) {
        String csv = projectService.generateCsvExport(user.getCompany());
        byte[] bytes = csv.getBytes(java.nio.charset.StandardCharsets.UTF_8);
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.parseMediaType("text/csv; charset=UTF-8"));
        headers.setContentDispositionFormData("attachment", "rapport_taches.csv");
        return new ResponseEntity<>(bytes, headers, HttpStatus.OK);
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
        List<Map<String, Object>> result = new ArrayList<>();
        for (Project project : projects) {
            result.add(enrichProject(project));
        }
        return ResponseEntity.ok(result);
    }

    @PostMapping({"/", ""})
    public ResponseEntity<Project> createProject(@AuthenticationPrincipal User user,
                                                   @RequestBody Map<String, Object> body) {
        Long leadId = body.containsKey("lead_id") ? Long.valueOf(body.get("lead_id").toString()) : null;
        @SuppressWarnings("unchecked")
        List<Long> memberIds = body.containsKey("member_ids")
                ? ((List<Object>) body.get("member_ids")).stream().map(o -> Long.valueOf(o.toString())).toList()
                : List.of();
        Project project = new Project();
        project.setTitle((String) body.get("title"));
        project.setDescription((String) body.getOrDefault("description", ""));
        if (body.containsKey("status")) project.setStatus(ProjectStatus.valueOf((String) body.get("status")));
        if (body.containsKey("priority")) project.setPriority(Priority.valueOf((String) body.get("priority")));
        if (body.containsKey("startDate")) project.setStartDate(LocalDate.parse((String) body.get("startDate")));
        if (body.containsKey("endDate")) project.setEndDate(LocalDate.parse((String) body.get("endDate")));
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(projectService.createProject(project, user, leadId, memberIds));
    }

    @GetMapping({"/{pk:[0-9]+}/", "/{pk:[0-9]+}"})
    public ResponseEntity<Map<String, Object>> getProject(@AuthenticationPrincipal User user,
                                                           @PathVariable Long pk) {
        Project project = projectService.getProject(pk, user.getCompany());
        return ResponseEntity.ok(enrichProject(project));
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

    private Map<String, Object> enrichProject(Project project) {
        Map<String, Object> map = objectMapper.convertValue(project, Map.class);
        long total = taskRepository.countByProject(project);
        long done = taskRepository.countByProjectAndStatus(project, TaskStatus.DONE);
        double completion = total > 0 ? Math.round((double) done / total * 100 * 10.0) / 10.0 : 0;
        map.put("task_completion_percentage", completion);
        map.put("member_count", memberRepository.countByProject(project));
        return map;
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
