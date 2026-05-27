package com.collabsme.activity;

import com.collabsme.user.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/activity")
public class ActivityLogController {

    private final ActivityLogRepository activityLogRepository;

    public ActivityLogController(ActivityLogRepository activityLogRepository) {
        this.activityLogRepository = activityLogRepository;
    }

    @GetMapping({"/", ""})
    public ResponseEntity<Page<ActivityLog>> list(@AuthenticationPrincipal User user,
                                                   @RequestParam(required = false) String actionType,
                                                   @RequestParam(name = "project_id", required = false) String projectId,
                                                   @RequestParam(defaultValue = "0") int page) {
        PageRequest pr = PageRequest.of(page, 20);
        if (actionType != null && !actionType.isEmpty()) {
            return ResponseEntity.ok(
                    activityLogRepository.findByCompanyAndActionTypeOrderByTimestampDesc(
                            user.getCompany(), actionType, pr));
        }
        if (projectId != null && !projectId.isEmpty()) {
            return ResponseEntity.ok(
                    activityLogRepository.findByCompanyAndProjectId(
                            user.getCompany(), projectId, pr));
        }
        return ResponseEntity.ok(
                activityLogRepository.findByCompanyOrderByTimestampDesc(user.getCompany(), pr));
    }
}
