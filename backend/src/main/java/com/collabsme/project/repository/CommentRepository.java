package com.collabsme.project.repository;

import com.collabsme.project.model.Comment;
import com.collabsme.project.model.Task;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface CommentRepository extends JpaRepository<Comment, Long> {
    List<Comment> findByTaskOrderByCreatedAtAsc(Task task);
    long countByTask(Task task);
    void deleteByTaskId(Long taskId);
}
