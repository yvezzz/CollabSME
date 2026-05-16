from django.db import models


class ActivityLog(models.Model):
    ACTION_TYPES = [
        ('PROJECT_CREATED', 'Projet créé'),
        ('PROJECT_UPDATED', 'Projet mis à jour'),
        ('TASK_CREATED', 'Tâche créée'),
        ('TASK_UPDATED', 'Tâche mise à jour'),
        ('MEMBER_ADDED', 'Membre ajouté'),
        ('MEMBER_REMOVED', 'Membre retiré'),
        ('COMMENT_ADDED', 'Commentaire ajouté'),
        ('OTHER', 'Autre'),
    ]

    company = models.ForeignKey(
        'companies.Company', on_delete=models.CASCADE, related_name='activities'
    )
    actor = models.ForeignKey(
        'authentication.User', on_delete=models.SET_NULL, null=True
    )
    action_type = models.CharField(
        max_length=50, choices=ACTION_TYPES, default='OTHER'
    )
    target_description = models.TextField(default='')
    metadata = models.JSONField(default=dict, blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name_plural = 'Activity logs'
        ordering = ['-timestamp']

    def __str__(self):
        actor_name = f'{self.actor}' if self.actor else 'Système'
        return f'[{self.timestamp}] {actor_name} - {self.action_type}'
