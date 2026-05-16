from django.db import models


class Notification(models.Model):
    NOTIFICATION_TYPES = [
        ('TASK_ASSIGNED', 'Nouvelle tâche'),
        ('TASK_UPDATED', 'Tâche mise à jour'),
        ('COMMENT_ADDED', 'Nouveau commentaire'),
        ('INVITATION_RECEIVED', 'Invitation reçue'),
        ('INVITATION_ACCEPTED', 'Invitation acceptée'),
        ('PROJECT_UPDATED', 'Projet mis à jour'),
        ('MENTION', 'Mention'),
        ('OTHER', 'Autre'),
    ]

    user = models.ForeignKey(
        'authentication.User',
        on_delete=models.CASCADE,
        related_name='notifications',
    )
    title = models.CharField(max_length=255, default='Notification')
    message = models.TextField(default='')
    notification_type = models.CharField(
        max_length=50, choices=NOTIFICATION_TYPES, default='OTHER'
    )
    is_read = models.BooleanField(default=False)
    related_id = models.CharField(max_length=50, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f'[{self.notification_type}] {self.title} - {self.user.email}'
