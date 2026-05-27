package com.collabsme.project.repository;

import com.collabsme.project.model.Attachment;
import com.collabsme.project.model.Task;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface AttachmentRepository extends JpaRepository<Attachment, Long> {
    List<Attachment> findByTask(Task task);
    long countByTask(Task task);
}
