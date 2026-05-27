package com.collabsme.project.controller;

import com.collabsme.project.model.*;
import com.collabsme.project.service.ProjectService;
import com.collabsme.project.service.TaskService;
import com.collabsme.user.User;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/projects/{pk:[0-9]+}/members")
public class MemberController {

    private final ProjectService projectService;
    private final TaskService taskService;

    public MemberController(ProjectService projectService, TaskService taskService) {
        this.projectService = projectService;
        this.taskService = taskService;
    }

    @GetMapping({"/", ""})
    public ResponseEntity<?> listMembers(@AuthenticationPrincipal User user, @PathVariable Long pk) {
        Project project = projectService.getProject(pk, user.getCompany());
        return ResponseEntity.ok(projectService.getMembers(project));
    }

    @PostMapping({"/", ""})
    public ResponseEntity<?> addMember(@AuthenticationPrincipal User user, @PathVariable Long pk,
                                        @RequestBody Map<String, Object> body) {
        Project project = projectService.getProject(pk, user.getCompany());
        Long userId = Long.valueOf(body.get("user").toString());
        String role = (String) body.getOrDefault("role", "MEMBER");
        ProjectMember member = projectService.addMember(project, user, userId, role);
        return ResponseEntity.status(HttpStatus.CREATED).body(member);
    }

    @DeleteMapping({"/{memberPk:[0-9]+}/", "/{memberPk:[0-9]+}"})
    public ResponseEntity<Void> removeMember(@AuthenticationPrincipal User user,
                                              @PathVariable Long pk, @PathVariable Long memberPk) {
        Project project = projectService.getProject(pk, user.getCompany());
        projectService.removeMember(project, user, memberPk);
        return ResponseEntity.noContent().build();
    }

    @PatchMapping({"/{memberPk:[0-9]+}/", "/{memberPk:[0-9]+}"})
    public ResponseEntity<?> updateMemberRole(@AuthenticationPrincipal User user,
                                               @PathVariable Long pk, @PathVariable Long memberPk,
                                               @RequestBody Map<String, String> body) {
        Project project = projectService.getProject(pk, user.getCompany());
        return ResponseEntity.ok(projectService.updateMemberRole(project, user, memberPk, body.get("role")));
    }
}
