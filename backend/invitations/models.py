import uuid
from django.db import models


class Invitation(models.Model):
    ROLE_CHOICES = [
        ('ADMIN', 'Admin'),
        ('LEAD', 'Chef d\'équipe'),
        ('MEMBER', 'Membre'),
    ]
    STATUS_CHOICES = [
        ('PENDING', 'En attente'),
        ('ACCEPTED', 'Acceptée'),
        ('DECLINED', 'Refusée'),
        ('EXPIRED', 'Expirée'),
    ]

    company = models.ForeignKey(
        'companies.Company', on_delete=models.CASCADE, related_name='invitations'
    )
    email = models.EmailField()
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='MEMBER')
    token = models.UUIDField(default=uuid.uuid4, unique=True, editable=False)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')
    invited_by = models.ForeignKey(
        'authentication.User', on_delete=models.SET_NULL, null=True
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        unique_together = ['company', 'email']

    def __str__(self):
        return f'{self.email} -> {self.company.name} ({self.status})'
