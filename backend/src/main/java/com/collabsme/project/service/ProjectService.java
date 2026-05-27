package com.collabsme.project.service;

import com.collabsme.activity.ActivityLog;
import com.collabsme.activity.ActivityLogRepository;
import com.collabsme.company.Company;
import com.collabsme.exception.ResourceNotFoundException;
import com.collabsme.project.model.*;
import com.collabsme.project.repository.*;
import com.collabsme.user.Role;
import com.collabsme.user.User;
import com.collabsme.user.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class ProjectService {

    private final ProjectRepository projectRepository;
    private final ProjectMemberRepository memberRepository;
    private final TaskRepository taskRepository;
    private final ActivityLogRepository activityLogRepository;
    private final UserRepository userRepository;

    public ProjectService(ProjectRepository projectRepository, ProjectMemberRepository memberRepository,
                          TaskRepository taskRepository, ActivityLogRepository activityLogRepository,
                          UserRepository userRepository) {
        this.projectRepository = projectRepository;
        this.memberRepository = memberRepository;
        this.taskRepository = taskRepository;
        this.activityLogRepository = activityLogRepository;
        this.userRepository = userRepository;
    }

    public Page<Project> getProjects(Company company, String status, int page, int size) {
        PageRequest pr = PageRequest.of(page, size);
        if (status != null && !status.isEmpty()) {
            try {
                ProjectStatus ps = ProjectStatus.valueOf(status);
                return projectRepository.findByCompanyAndStatus(company, ps, pr);
            } catch (IllegalArgumentException e) {
                // ignore invalid status filter
            }
        }
        return null; // caller handles
    }

    public List<Project> getProjectsByCompany(Company company) {
        return projectRepository.findByCompany(company);
    }

    public Project getProject(Long id, Company company) {
        Project project = projectRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Projet introuvable."));
        if (!project.getCompany().getId().equals(company.getId())) {
            throw new ResourceNotFoundException("Projet introuvable.");
        }
        return project;
    }

    @Transactional
    public Project createProject(Project project, User user) {
        project.setCompany(user.getCompany());
        project.setCreatedBy(user);
        Project saved = projectRepository.save(project);

        ProjectMember pm = new ProjectMember();
        pm.setProject(saved);
        pm.setUser(user);
        pm.setRole(Role.ADMIN);
        memberRepository.save(pm);

        logActivity(user.getCompany(), user, "PROJECT_CREATED",
                "Projet \"" + project.getTitle() + "\" créé",
                "{\"project_id\":\"" + saved.getId() + "\"}");
        return saved;
    }

    @Transactional
    public Project updateProject(Long id, Project updates, User user) {
        Project project = getProject(id, user.getCompany());
        checkRole(project, user, Role.ADMIN, Role.LEAD);

        if (updates.getTitle() != null) project.setTitle(updates.getTitle());
        if (updates.getDescription() != null) project.setDescription(updates.getDescription());
        if (updates.getStatus() != null) project.setStatus(updates.getStatus());
        if (updates.getPriority() != null) project.setPriority(updates.getPriority());
        if (updates.getBudget() != null) project.setBudget(updates.getBudget());
        if (updates.getStartDate() != null) project.setStartDate(updates.getStartDate());
        if (updates.getEndDate() != null) project.setEndDate(updates.getEndDate());
        if (updates.getTags() != null) project.setTags(updates.getTags());
        if (updates.getCustomFields() != null) project.setCustomFields(updates.getCustomFields());
        if (updates.getKey() != null) project.setKey(updates.getKey());

        return projectRepository.save(project);
    }

    @Transactional
    public void deleteProject(Long id, User user) {
        Project project = getProject(id, user.getCompany());
        checkRole(project, user, Role.ADMIN);
        projectRepository.delete(project);
    }

    @Transactional
    public Project updateStatus(Long id, String action, User user) {
        Project project = getProject(id, user.getCompany());
        checkRole(project, user, Role.ADMIN, Role.LEAD);

        Map<String, ProjectStatus> validActions = Map.of(
                "activate", ProjectStatus.ACTIVE,
                "validate", ProjectStatus.COMPLETED,
                "archive", ProjectStatus.ARCHIVED,
                "draft", ProjectStatus.DRAFT,
                "hold", ProjectStatus.ON_HOLD,
                "plan", ProjectStatus.PLANNING
        );
        ProjectStatus newStatus = validActions.get(action);
        if (newStatus == null) {
            throw new IllegalArgumentException("Action invalide.");
        }
        project.setStatus(newStatus);
        project = projectRepository.save(project);

        logActivity(user.getCompany(), user, "PROJECT_UPDATED",
                "Projet \"" + project.getTitle() + "\" : " + newStatus,
                "{\"project_id\":\"" + project.getId() + "\",\"status\":\"" + newStatus + "\"}");
        return project;
    }

    public Map<String, Object> getDashboardStats(Company company) {
        long totalProjects = projectRepository.countByCompany(company);
        long activeTasks = taskRepository.countByProjectCompanyAndStatusIn(company,
                List.of(TaskStatus.TODO, TaskStatus.IN_PROGRESS, TaskStatus.REVIEW));
        long totalMembers = userRepository.findByCompanyOrderByEmail(company).size();
        return Map.of(
                "total_projects", totalProjects,
                "active_tasks", activeTasks,
                "total_members", totalMembers
        );
    }

    public Map<String, Object> getReports(Company company) {
        List<Project> projects = projectRepository.findByCompany(company);
        long totalProjects = projects.size();
        long totalTasks = taskRepository.countByProjectCompany(company);
        long done = taskRepository.countByProjectCompanyAndStatus(company, TaskStatus.DONE);
        double completionRate = totalTasks > 0 ? Math.round((double) done / totalTasks * 100 * 10.0) / 10.0 : 0;
        long overdue = taskRepository.findOverdue(company, LocalDate.now(),
                List.of(TaskStatus.TODO, TaskStatus.IN_PROGRESS, TaskStatus.REVIEW)).size();

        Map<String, Long> byStatus = new HashMap<>();
        for (Project p : projects) {
            String s = p.getStatus().name();
            byStatus.merge(s, 1L, Long::sum);
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("total_projects", totalProjects);
        result.put("total_tasks", totalTasks);
        result.put("completion_rate", completionRate);
        result.put("overdue_tasks", overdue);
        result.put("projects_by_status", byStatus);
        return result;
    }

    public Map<String, Object> getProjectStats(Project project) {
        long total = taskRepository.countByProject(project);
        long done = taskRepository.countByProjectAndStatus(project, TaskStatus.DONE);
        long overdue = taskRepository.findByProjectAndStatusIn(project,
                List.of(TaskStatus.TODO, TaskStatus.IN_PROGRESS, TaskStatus.REVIEW)).stream()
                .filter(t -> t.getDueDate() != null && t.getDueDate().isBefore(LocalDate.now()))
                .count();

        double completionRate = total > 0 ? (double) done / total * 100 : 0;

        Map<String, Long> byStatus = new LinkedHashMap<>();
        for (TaskStatus s : TaskStatus.values()) {
            long count = taskRepository.countByProjectAndStatus(project, s);
            if (count > 0) byStatus.put(s.name(), count);
        }

        List<Map<String, Object>> perMember = new ArrayList<>();
        for (ProjectMember pm : memberRepository.findByProject(project)) {
            long count = taskRepository.countByProjectAndAssignedToAndStatusIn(project, pm.getUser(),
                    List.of(TaskStatus.TODO, TaskStatus.IN_PROGRESS, TaskStatus.REVIEW, TaskStatus.DONE));
            perMember.add(Map.of(
                    "user", pm.getUser().getFirstName() + " " + pm.getUser().getLastName(),
                    "count", count
            ));
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("total_tasks", total);
        result.put("completion_rate", completionRate);
        result.put("tasks_by_status", byStatus);
        result.put("tasks_per_member", perMember);
        result.put("overdue_tasks", overdue);
        return result;
    }

    public List<Map<String, Object>> getWorkload(Project project) {
        List<Map<String, Object>> data = new ArrayList<>();
        for (ProjectMember pm : memberRepository.findByProject(project)) {
            long active = taskRepository.countByProjectAndAssignedToAndStatusIn(project, pm.getUser(),
                    List.of(TaskStatus.TODO, TaskStatus.IN_PROGRESS, TaskStatus.REVIEW));
            long done = taskRepository.countByProjectAndAssignedToAndStatus(project, pm.getUser(), TaskStatus.DONE);
            data.add(Map.of(
                    "user_id", pm.getUser().getId(),
                    "name", pm.getUser().getFirstName() + " " + pm.getUser().getLastName(),
                    "email", pm.getUser().getEmail(),
                    "role", pm.getRole().name(),
                    "active_tasks", active,
                    "completed_tasks", done,
                    "total_tasks", active + done
            ));
        }
        return data;
    }

    public List<ProjectMember> getMembers(Project project) {
        return memberRepository.findByProject(project);
    }

    @Transactional
    public ProjectMember addMember(Project project, User currentUser, Long userId, String roleStr) {
        checkRole(project, currentUser, Role.ADMIN, Role.LEAD);
        User targetUser = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Utilisateur introuvable."));
        if (!project.getCompany().getId().equals(targetUser.getCompany().getId())) {
            throw new ResourceNotFoundException("Utilisateur introuvable.");
        }

        return memberRepository.findByProjectAndUser(project, targetUser)
                .map(existing -> {
                    existing.setRole(parseRole(roleStr));
                    return memberRepository.save(existing);
                })
                .orElseGet(() -> {
                    ProjectMember pm = new ProjectMember();
                    pm.setProject(project);
                    pm.setUser(targetUser);
                    pm.setRole(parseRole(roleStr));
                    return memberRepository.save(pm);
                });
    }

    @Transactional
    public void removeMember(Project project, User currentUser, Long memberPk) {
        checkRole(project, currentUser, Role.ADMIN, Role.LEAD);
        ProjectMember pm = memberRepository.findById(memberPk)
                .orElseThrow(() -> new ResourceNotFoundException("Membre introuvable."));
        if (!pm.getProject().getId().equals(project.getId())) {
            throw new ResourceNotFoundException("Membre introuvable.");
        }
        memberRepository.delete(pm);
    }

    @Transactional
    public ProjectMember updateMemberRole(Project project, User currentUser, Long memberPk, String roleStr) {
        checkRole(project, currentUser, Role.ADMIN);
        ProjectMember pm = memberRepository.findById(memberPk)
                .orElseThrow(() -> new ResourceNotFoundException("Membre introuvable."));
        if (!pm.getProject().getId().equals(project.getId())) {
            throw new ResourceNotFoundException("Membre introuvable.");
        }
        Role role = Role.valueOf(roleStr);
        pm.setRole(role);
        return memberRepository.save(pm);
    }

    public Map<String, Object> globalSearch(Company company, String query) {
        if (query == null || query.length() < 2) {
            return Map.of("projects", Collections.emptyList(), "tasks", Collections.emptyList());
        }
        List<Map<String, Object>> projects = projectRepository.search(company, query).stream()
                .map(p -> Map.<String, Object>of("id", p.getId(), "title", p.getTitle(), "key", p.getKey() != null ? p.getKey() : ""))
                .collect(Collectors.toList());
        List<Map<String, Object>> tasks = taskRepository.searchByCompany(company, query).stream()
                .map(t -> Map.<String, Object>of(
                        "id", t.getId(),
                        "title", t.getTitle(),
                        "status", t.getStatus().name(),
                        "project_id", t.getProject().getId(),
                        "project_title", t.getProject().getTitle()
                ))
                .collect(Collectors.toList());
        return Map.of("projects", projects, "tasks", tasks);
    }

    public List<Map<String, Object>> getCalendarTasks(Company company, Integer month, Integer year) {
        LocalDate now = LocalDate.now();
        int m = month != null ? month : now.getMonthValue();
        int y = year != null ? year : now.getYear();
        return taskRepository.findCalendarTasks(company, y, m).stream()
                .map(t -> {
                    Map<String, Object> map = new LinkedHashMap<>();
                    map.put("id", t.getId());
                    map.put("title", t.getTitle());
                    map.put("status", t.getStatus().name());
                    map.put("priority", t.getPriority().name());
                    map.put("due_date", t.getDueDate() != null ? t.getDueDate().toString() : null);
                    map.put("project_id", t.getProject().getId());
                    map.put("project_title", t.getProject().getTitle());
                    return map;
                })
                .collect(Collectors.toList());
    }

    private void checkRole(Project project, User user, Role... allowedRoles) {
        memberRepository.findByProjectAndUser(project, user)
                .filter(pm -> Arrays.asList(allowedRoles).contains(pm.getRole()))
                .orElseThrow(() -> new SecurityException("Action non autorisée."));
    }

    private void logActivity(Company company, User actor, String actionType, String description, String metadata) {
        ActivityLog log = new ActivityLog();
        log.setCompany(company);
        log.setActor(actor);
        log.setActionType(actionType);
        log.setTargetDescription(description);
        log.setMetadata(metadata);
        activityLogRepository.save(log);
    }

    private static Role parseRole(String roleStr) {
        try {
            return Role.valueOf(roleStr);
        } catch (IllegalArgumentException e) {
            return Role.MEMBER;
        }
    }
}
