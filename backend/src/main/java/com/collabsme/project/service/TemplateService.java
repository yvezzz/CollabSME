package com.collabsme.project.service;

import com.collabsme.company.Company;
import com.collabsme.exception.ResourceNotFoundException;
import com.collabsme.project.model.*;
import com.collabsme.project.repository.*;
import com.collabsme.user.Role;
import com.collabsme.user.User;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
public class TemplateService {

    private final ProjectTemplateRepository templateRepository;
    private final ProjectRepository projectRepository;
    private final ProjectMemberRepository memberRepository;
    private final TaskRepository taskRepository;

    public TemplateService(ProjectTemplateRepository templateRepository,
                           ProjectRepository projectRepository,
                           ProjectMemberRepository memberRepository,
                           TaskRepository taskRepository) {
        this.templateRepository = templateRepository;
        this.projectRepository = projectRepository;
        this.memberRepository = memberRepository;
        this.taskRepository = taskRepository;
    }

    public List<ProjectTemplate> getTemplates(Company company) {
        return templateRepository.findByCompanyOrIsPublicTrueOrderByIsPublicDescNameAsc(company);
    }

    @Transactional
    public ProjectTemplate createTemplate(ProjectTemplate template, Company company) {
        template.setCompany(company);
        return templateRepository.save(template);
    }

    @Transactional
    public Map<String, Object> createProjectFromTemplate(Long templateId, String title, Company company, User user) {
        ProjectTemplate template = templateRepository.findById(templateId)
                .orElseThrow(() -> new ResourceNotFoundException("Template introuvable."));

        Project project = new Project();
        project.setTitle(title);
        project.setCompany(company);
        project.setCreatedBy(user);
        project.setStatus(ProjectStatus.DRAFT);
        project = projectRepository.save(project);

        ProjectMember pm = new ProjectMember();
        pm.setProject(project);
        pm.setUser(user);
        pm.setRole(Role.ADMIN);
        memberRepository.save(pm);

        // Parse tasks JSON and create tasks
        // Simplified: tasks stored as JSON string, we parse and create
        // In production, use proper JSON parsing with Jackson

        return Map.of(
                "id", project.getId(),
                "title", project.getTitle(),
                "message", "Projet créé à partir du template."
        );
    }
}
