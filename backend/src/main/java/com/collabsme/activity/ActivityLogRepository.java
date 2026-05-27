package com.collabsme.activity;

import com.collabsme.company.Company;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ActivityLogRepository extends JpaRepository<ActivityLog, Long> {
    Page<ActivityLog> findByCompanyOrderByTimestampDesc(Company company, Pageable pageable);
    Page<ActivityLog> findByCompanyAndActionTypeOrderByTimestampDesc(Company company, String actionType, Pageable pageable);

    @Query("SELECT a FROM ActivityLog a WHERE a.company = :company AND a.metadata LIKE %:projectId% ORDER BY a.timestamp DESC")
    Page<ActivityLog> findByCompanyAndProjectId(@Param("company") Company company, @Param("projectId") String projectId, Pageable pageable);
}
