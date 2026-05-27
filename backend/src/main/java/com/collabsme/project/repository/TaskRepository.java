package com.collabsme.project.repository;

import com.collabsme.company.Company;
import com.collabsme.project.model.Project;
import com.collabsme.project.model.Task;
import com.collabsme.project.model.TaskStatus;
import com.collabsme.user.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.LocalDate;
import java.util.List;

public interface TaskRepository extends JpaRepository<Task, Long> {
    @Query("SELECT t FROM Task t WHERE t.project = :project ORDER BY t.order ASC, t.createdAt DESC")
    List<Task> findByProjectOrdered(@Param("project") Project project);
    Page<Task> findByProject(Project project, Pageable pageable);
    Page<Task> findByProjectAndStatus(Project project, TaskStatus status, Pageable pageable);
    Page<Task> findByProjectAndAssignedTo(Project project, User assignedTo, Pageable pageable);

    @Query("SELECT t FROM Task t WHERE t.project = :project AND (LOWER(t.title) LIKE LOWER(CONCAT('%', :q, '%')) OR LOWER(t.description) LIKE LOWER(CONCAT('%', :q, '%'))) ORDER BY t.order ASC, t.createdAt DESC")
    Page<Task> search(@Param("project") Project project, @Param("q") String q, Pageable pageable);

    long countByProjectAndStatus(Project project, TaskStatus status);
    long countByProjectAndStatusIn(Project project, List<TaskStatus> statuses);
    List<Task> findByProjectAndStatusIn(Project project, List<TaskStatus> statuses);
    long countByProject(Project project);

    Page<Task> findByAssignedToOrderByCreatedAtDesc(User assignedTo, Pageable pageable);

    @Query("SELECT t FROM Task t WHERE t.project.company = :company AND t.dueDate IS NOT NULL AND YEAR(t.dueDate) = :year AND MONTH(t.dueDate) = :month ORDER BY t.dueDate ASC")
    List<Task> findByCompanyAndDueDateMonth(@Param("company") Company company, @Param("year") int year, @Param("month") int month);

    @Query("SELECT t FROM Task t WHERE t.project.company = :company AND t.dueDate < :date AND t.status IN :statuses")
    List<Task> findOverdue(@Param("company") Company company, @Param("date") LocalDate date, @Param("statuses") List<TaskStatus> statuses);

    long countByProjectCompanyAndStatusIn(Company company, List<TaskStatus> statuses);
    long countByProjectCompanyAndStatus(Company company, TaskStatus status);
    long countByProjectCompany(Company company);

    long countByProjectAndAssignedToAndStatusIn(Project project, User user, List<TaskStatus> statuses);
    long countByProjectAndAssignedToAndStatus(Project project, User user, TaskStatus status);

    // For my-tasks
    @Query("SELECT t FROM Task t WHERE t.assignedTo = :user ORDER BY t.createdAt DESC")
    List<Task> findByAssignedTo(@Param("user") User user);

    // For global search
    @Query("SELECT t FROM Task t WHERE t.project.company = :company AND LOWER(t.title) LIKE LOWER(CONCAT('%', :q, '%'))")
    List<Task> searchByCompany(@Param("company") Company company, @Param("q") String q);

    // For calendar
    @Query("SELECT t FROM Task t WHERE t.project.company = :company AND t.dueDate IS NOT NULL AND YEAR(t.dueDate) = :year AND MONTH(t.dueDate) = :month ORDER BY t.dueDate ASC")
    List<Task> findCalendarTasks(@Param("company") Company company, @Param("year") int year, @Param("month") int month);
}
