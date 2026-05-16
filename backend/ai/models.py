from django.db import models


class AIChat(models.Model):
    user = models.ForeignKey(
        'authentication.User', on_delete=models.CASCADE, related_name='ai_chats'
    )
    role = models.CharField(max_length=20, default='user')  # 'user' or 'assistant'
    content = models.TextField()
    model_used = models.CharField(max_length=100, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['created_at']

    def __str__(self):
        return f'{self.user.email} - {self.role}: {self.content[:50]}'
