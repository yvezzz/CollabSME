package com.collabsme.ai;

import com.collabsme.user.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface AIChatRepository extends JpaRepository<AIChat, Long> {
    List<AIChat> findByUserOrderByCreatedAtAsc(User user);
    List<AIChat> findTop20ByUserOrderByCreatedAtDesc(User user);
    void deleteByUser(User user);
}
