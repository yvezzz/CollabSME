package com.collabsme.activity;

import com.collabsme.company.CompanyRepository;
import com.collabsme.exception.ResourceNotFoundException;
import com.collabsme.user.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/activity")
public class ActivityLogController {

    private final ActivityLogRepository activityLogRepository;
    private final CompanyRepository companyRepository;

    public ActivityLogController(ActivityLogRepository activityLogRepository,
                                  CompanyRepository companyRepository) {
        this.activityLogRepository = activityLogRepository;
        this.companyRepository = companyRepository;
    }

    @GetMapping({"/", ""})
    public ResponseEntity<Page<Map<String, Object>>> list(@AuthenticationPrincipal User user,
                                                           @RequestParam(required = false) String actionType,
                                                           @RequestParam(name = "project_id", required = false) String projectId,
                                                           @RequestParam(defaultValue = "0") int page) {
        if (user.getCompany() == null || user.getCompany().getId() == null) {
            throw new ResourceNotFoundException("Aucune entreprise associée.");
        }
        var company = companyRepository.findById(user.getCompany().getId())
                .orElseThrow(() -> new ResourceNotFoundException("Aucune entreprise associée."));
        PageRequest pr = PageRequest.of(page, 20);
        Page<ActivityLog> logs;
        if (actionType != null && !actionType.isEmpty()) {
            logs = activityLogRepository.findByCompanyAndActionTypeOrderByTimestampDesc(company, actionType, pr);
        } else if (projectId != null && !projectId.isEmpty()) {
            logs = activityLogRepository.findByCompanyAndProjectId(company, projectId, pr);
        } else {
            logs = activityLogRepository.findByCompanyOrderByTimestampDesc(company, pr);
        }
        return ResponseEntity.ok(logs.map(this::toMap));
    }

    private Map<String, Object> toMap(ActivityLog log) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", log.getId());
        if (log.getActor() != null) {
            map.put("actor_name", log.getActor().getFirstName() + " " + log.getActor().getLastName());
            map.put("actor_avatar", null);
        } else {
            map.put("actor_name", "Système");
            map.put("actor_avatar", null);
        }
        map.put("action_type", log.getActionType());
        map.put("target_description", log.getTargetDescription());
        map.put("metadata", log.getMetadata());
        map.put("timestamp", log.getTimestamp() != null ? log.getTimestamp().toString() : null);
        return map;
    }
}
