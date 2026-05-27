from django.db import models


class Project(models.Model):
    STATUS_CHOICES = [
        ('DRAFT', 'Brouillon'),
        ('PLANNING', 'Planification'),
        ('ACTIVE', 'Actif'),
        ('ON_HOLD', 'En pause'),
        ('COMPLETED', 'Terminé'),
        ('ARCHIVED', 'Archivé'),
    ]
    PRIORITY_CHOICES = [
        ('LOW', 'Basse'),
        ('MEDIUM', 'Moyenne'),
        ('HIGH', 'Haute'),
        ('CRITICAL', 'Critique'),
    ]

    company = models.ForeignKey(
        'companies.Company',
        on_delete=models.CASCADE,
        related_name='projects',
    )
    key = models.CharField(max_length=10, blank=True, null=True)
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True, default='')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='DRAFT')
    priority = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default='MEDIUM')
    budget = models.DecimalField(max_digits=12, decimal_places=2, null=True, blank=True)
    actual_cost = models.DecimalField(max_digits=12, decimal_places=2, default=0.00)
    tags = models.JSONField(default=list, blank=True)
    custom_fields = models.JSONField(default=dict, blank=True)
    created_by = models.ForeignKey(
        'authentication.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_projects',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    start_date = models.DateField(null=True, blank=True)
    end_date = models.DateField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.key or ""} {self.title}'.strip()

    @property
    def task_completion_percentage(self):
        total = self.tasks.count()
        if total == 0:
            return 0
        done = self.tasks.filter(status='DONE').count()
        return int((done / total) * 100)

    @property
    def member_count(self):
        return self.members.count()


class ProjectTemplate(models.Model):
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True, default='')
    icon = models.CharField(max_length=10, default='📁')
    company = models.ForeignKey('companies.Company', on_delete=models.CASCADE, null=True, blank=True, related_name='templates')
    is_public = models.BooleanField(default=False)
    tasks = models.JSONField(default=list, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

    def create_project(self, title, company, created_by):
        project = Project.objects.create(
            title=title,
            company=company,
            created_by=created_by,
            status='DRAFT',
        )
        ProjectMember.objects.create(
            project=project,
            user=created_by,
            role='ADMIN',
        )
        for task_data in self.tasks:
            Task.objects.create(
                project=project,
                title=task_data.get('title', 'Nouvelle tâche'),
                description=task_data.get('description', ''),
                priority=task_data.get('priority', 'MEDIUM'),
                created_by=created_by,
            )
        return project


class ProjectMember(models.Model):
    ROLE_CHOICES = [
        ('ADMIN', 'Admin'),
        ('LEAD', 'Chef d\'équipe'),
        ('MEMBER', 'Membre'),
    ]

    project = models.ForeignKey(
        Project, on_delete=models.CASCADE, related_name='members'
    )
    user = models.ForeignKey(
        'authentication.User', on_delete=models.CASCADE, related_name='project_memberships'
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='MEMBER')
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ['project', 'user']

    def __str__(self):
        return f'{self.user.email} - {self.project.title} ({self.role})'


class Task(models.Model):
    STATUS_CHOICES = [
        ('TODO', 'À faire'),
        ('IN_PROGRESS', 'En cours'),
        ('REVIEW', 'En révision'),
        ('DONE', 'Terminé'),
    ]
    PRIORITY_CHOICES = [
        ('LOW', 'Basse'),
        ('MEDIUM', 'Moyenne'),
        ('HIGH', 'Haute'),
        ('CRITICAL', 'Critique'),
    ]

    project = models.ForeignKey(
        Project, on_delete=models.CASCADE, related_name='tasks'
    )
    parent_task = models.ForeignKey(
        'self', on_delete=models.SET_NULL, null=True, blank=True, related_name='sub_tasks'
    )
    public_id = models.CharField(max_length=20, blank=True, null=True)
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True, default='')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='TODO')
    priority = models.CharField(max_length=20, choices=PRIORITY_CHOICES, default='MEDIUM')
    assigned_to = models.ForeignKey(
        'authentication.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_tasks',
    )
    estimated_hours = models.DecimalField(max_digits=8, decimal_places=2, null=True, blank=True)
    actual_hours = models.DecimalField(max_digits=8, decimal_places=2, default=0.00)
    tags = models.JSONField(default=list, blank=True)
    custom_fields = models.JSONField(default=dict, blank=True)
    order = models.IntegerField(default=0)
    created_by = models.ForeignKey(
        'authentication.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_tasks',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    due_date = models.DateField(null=True, blank=True)
    start_date = models.DateField(null=True, blank=True)

    class Meta:
        ordering = ['order', '-created_at']

    def __str__(self):
        return f'[{self.project.key or ""}] {self.title}'


class ChecklistItem(models.Model):
    task = models.ForeignKey(
        Task, on_delete=models.CASCADE, related_name='checklist_items'
    )
    title = models.CharField(max_length=255)
    is_completed = models.BooleanField(default=False)
    order = models.IntegerField(default=0)

    class Meta:
        ordering = ['order']

    def __str__(self):
        return self.title


class Comment(models.Model):
    task = models.ForeignKey(
        Task, on_delete=models.CASCADE, related_name='comments'
    )
    parent = models.ForeignKey(
        'self', on_delete=models.CASCADE, null=True, blank=True, related_name='replies'
    )
    author = models.ForeignKey(
        'authentication.User', on_delete=models.SET_NULL, null=True
    )
    content = models.TextField()
    mentions = models.JSONField(default=list, blank=True)
    reactions = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f'Comment by {self.author} on {self.task}'


class Attachment(models.Model):
    task = models.ForeignKey(
        Task, on_delete=models.CASCADE, related_name='attachments'
    )
    file = models.FileField(upload_to='attachments/%Y/%m/%d/')
    original_filename = models.CharField(max_length=255, blank=True)
    file_size = models.IntegerField(default=0)
    uploaded_by = models.ForeignKey(
        'authentication.User', on_delete=models.SET_NULL, null=True
    )
    uploaded_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.original_filename or self.file.name
