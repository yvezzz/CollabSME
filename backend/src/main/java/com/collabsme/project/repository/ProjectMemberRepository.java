package com.collabsme.project.repository;

import com.collabsme.project.model.Project;
import com.collabsme.project.model.ProjectMember;
import com.collabsme.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface ProjectMemberRepository extends JpaRepository<ProjectMember, Long> {
    List<ProjectMember> findByProject(Project project);
    Optional<ProjectMember> findByProjectAndUser(Project project, User user);
    boolean existsByProjectAndUser(Project project, User user);
    long countByProject(Project project);
}
