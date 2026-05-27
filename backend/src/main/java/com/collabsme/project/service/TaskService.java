package com.collabsme.project.service;

import com.collabsme.activity.ActivityLog;
import com.collabsme.activity.ActivityLogRepository;
import com.collabsme.company.Company;
import com.collabsme.exception.ResourceNotFoundException;
import com.collabsme.project.model.*;
import com.collabsme.project.repository.*;
import com.collabsme.user.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDate;
import java.util.*;

@Service
public class TaskService {

    private final TaskRepository taskRepository;
    private final ChecklistItemRepository checklistItemRepository;
    private final CommentRepository commentRepository;
    private final AttachmentRepository attachmentRepository;
    private final ActivityLogRepository activityLogRepository;
    private final ProjectMemberRepository memberRepository;

    public TaskService(TaskRepository taskRepository, ChecklistItemRepository checklistItemRepository,
                       CommentRepository commentRepository, AttachmentRepository attachmentRepository,
                       ActivityLogRepository activityLogRepository,
                       ProjectMemberRepository memberRepository) {
        this.taskRepository = taskRepository;
        this.checklistItemRepository = checklistItemRepository;
        this.commentRepository = commentRepository;
        this.attachmentRepository = attachmentRepository;
        this.activityLogRepository = activityLogRepository;
        this.memberRepository = memberRepository;
    }

    public Page<Task> getTasks(Project project, String status, String assignedTo, String search,
                               int page, int size, String orderBy) {
        PageRequest pr = PageRequest.of(page, size);
        if (status != null && !status.isEmpty()) {
            try {
                return taskRepository.findByProjectAndStatus(project, TaskStatus.valueOf(status), pr);
            } catch (IllegalArgumentException e) {}
        }
        if (assignedTo != null && !assignedTo.isEmpty()) {
            // simple approach - find by user id
        }
        if (search != null && !search.isEmpty()) {
            return taskRepository.search(project, search, pr);
        }
        return null; // caller handles default
    }

    public Task getTask(Project project, Long taskId) {
        return taskRepository.findById(taskId)
                .filter(t -> t.getProject().getId().equals(project.getId()))
                .orElseThrow(() -> new ResourceNotFoundException("Tâche introuvable."));
    }

    @Transactional
    public Task createTask(Task task, Project project, User user) {
        task.setProject(project);
        task.setCreatedBy(user);
        Task saved = taskRepository.save(task);

        logActivity(user.getCompany(), user, "TASK_CREATED",
                "Tâche \"" + task.getTitle() + "\" créée",
                "{\"project_id\":\"" + project.getId() + "\",\"task_id\":\"" + saved.getId() + "\"}");
        return saved;
    }

    @Transactional
    public Task updateTaskStatus(Project project, Long taskId, String newStatus) {
        Task task = getTask(project, taskId);
        task.setStatus(TaskStatus.valueOf(newStatus));
        task = taskRepository.save(task);

        logActivity(project.getCompany(), task.getCreatedBy() != null ? task.getCreatedBy() : null,
                "TASK_UPDATED",
                "Tâche \"" + task.getTitle() + "\" : " + newStatus,
                "{\"project_id\":\"" + project.getId() + "\",\"task_id\":\"" + task.getId() + "\",\"status\":\"" + newStatus + "\"}");
        return task;
    }

    @Transactional
    public Task reorderTask(Project project, String taskIdStr, String newStatus, int newOrder) {
        Long taskId = Long.parseLong(taskIdStr);
        Task task = getTask(project, taskId);
        task.setStatus(TaskStatus.valueOf(newStatus));
        task.setOrder(newOrder);
        return taskRepository.save(task);
    }

    public Page<Task> getMyTasks(User user, int page, int size) {
        return taskRepository.findByAssignedToOrderByCreatedAtDesc(user, PageRequest.of(page, size));
    }

    @Transactional
    public Comment addComment(Project project, Long taskId, String content, String mentions, User user) {
        Task task = getTask(project, taskId);
        Comment comment = new Comment();
        comment.setTask(task);
        comment.setContent(content);
        comment.setMentions(mentions != null ? mentions : "[]");
        comment.setAuthor(user);
        return commentRepository.save(comment);
    }

    @Transactional
    public ChecklistItem addChecklistItem(Project project, Long taskId, String title) {
        Task task = getTask(project, taskId);
        ChecklistItem item = new ChecklistItem();
        item.setTask(task);
        item.setTitle(title);
        return checklistItemRepository.save(item);
    }

    @Transactional
    public ChecklistItem updateChecklistItem(Project project, Long taskId, Long itemId,
                                              boolean isCompleted, String title) {
        Task task = getTask(project, taskId);
        ChecklistItem item = checklistItemRepository.findById(itemId)
                .filter(i -> i.getTask().getId().equals(task.getId()))
                .orElseThrow(() -> new ResourceNotFoundException("Sous-tâche introuvable."));
        if (title != null) item.setTitle(title);
        item.setCompleted(isCompleted);
        return checklistItemRepository.save(item);
    }

    public Attachment uploadAttachment(Project project, Long taskId, MultipartFile file,
                                        String uploadDir, User user) throws IOException {
        Task task = getTask(project, taskId);
        Path dir = Paths.get(uploadDir);
        Files.createDirectories(dir);
        String filename = System.currentTimeMillis() + "_" + file.getOriginalFilename();
        Path target = dir.resolve(filename);
        Files.copy(file.getInputStream(), target);

        Attachment attachment = new Attachment();
        attachment.setTask(task);
        attachment.setFilePath("/uploads/" + filename);
        attachment.setOriginalFilename(file.getOriginalFilename());
        attachment.setFileSize((int) file.getSize());
        attachment.setUploadedBy(user);
        return attachmentRepository.save(attachment);
    }

    public List<Map<String, Object>> getActivity(Company company, int limit) {
        return activityLogRepository.findByCompanyOrderByTimestampDesc(company, PageRequest.of(0, limit))
                .stream()
                .map(a -> {
                    Map<String, Object> map = new LinkedHashMap<>();
                    map.put("id", a.getId());
                    map.put("actor_name", a.getActor() != null ?
                            a.getActor().getFirstName() + " " + a.getActor().getLastName() : "Système");
                    map.put("actor_avatar", a.getActor() != null ? a.getActor().getAvatarUrl() : null);
                    map.put("action_type", a.getActionType());
                    map.put("target_description", a.getTargetDescription());
                    map.put("timestamp", a.getTimestamp());
                    map.put("metadata", a.getMetadata());
                    return map;
                })
                .collect(ArrayList::new, ArrayList::add, ArrayList::addAll);
    }

    private void logActivity(Company company, User actor, String actionType, String description, String metadata) {
        ActivityLog log = new ActivityLog();
        log.setCompany(company);
        log.setActor(actor);
        log.setActionType(actionType);
        log.setTargetDescription(description);
        log.setMetadata(metadata);
        activityLogRepository.save(log);
    }
}
