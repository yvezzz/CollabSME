package com.collabsme.project.repository;

import com.collabsme.project.model.ChecklistItem;
import com.collabsme.project.model.Task;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface ChecklistItemRepository extends JpaRepository<ChecklistItem, Long> {
    List<ChecklistItem> findByTaskOrderByOrderAsc(Task task);
}
