package com.collabsme.project.repository;

import com.collabsme.company.Company;
import com.collabsme.project.model.Project;
import com.collabsme.project.model.ProjectStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface ProjectRepository extends JpaRepository<Project, Long> {
    Page<Project> findByCompanyOrderByCreatedAtDesc(Company company, Pageable pageable);
    List<Project> findByCompany(Company company);
    List<Project> findByCompanyAndStatus(Company company, ProjectStatus status);
    Page<Project> findByCompanyAndStatus(Company company, ProjectStatus status, Pageable pageable);

    @Query("SELECT p FROM Project p WHERE p.company = :company AND (LOWER(p.title) LIKE LOWER(CONCAT('%', :q, '%')) OR LOWER(p.description) LIKE LOWER(CONCAT('%', :q, '%')) OR LOWER(p.key) LIKE LOWER(CONCAT('%', :q, '%'))) ORDER BY p.createdAt DESC")
    List<Project> search(@Param("company") Company company, @Param("q") String q);

    long countByCompany(Company company);
}
