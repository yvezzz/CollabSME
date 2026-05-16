from django.db import models


class Company(models.Model):
    SUBSCRIPTION_CHOICES = [
        ('FREE', 'Gratuit'),
        ('BASIC', 'Basique'),
        ('PRO', 'Professionnel'),
        ('ENTERPRISE', 'Entreprise'),
    ]

    name = models.CharField(max_length=255)
    sector = models.CharField(max_length=100, blank=True, null=True)
    size = models.CharField(max_length=50, blank=True, null=True)
    logo_url = models.URLField(blank=True, null=True)
    subscription_status = models.CharField(
        max_length=20, choices=SUBSCRIPTION_CHOICES, default='FREE'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name_plural = 'Companies'
        ordering = ['-created_at']

    def __str__(self):
        return self.name
