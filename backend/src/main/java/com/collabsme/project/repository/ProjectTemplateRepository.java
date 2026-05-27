package com.collabsme.project.repository;

import com.collabsme.company.Company;
import com.collabsme.project.model.ProjectTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ProjectTemplateRepository extends JpaRepository<ProjectTemplate, Long> {
    List<ProjectTemplate> findByCompanyOrIsPublicTrueOrderByIsPublicDescNameAsc(Company company);
}
