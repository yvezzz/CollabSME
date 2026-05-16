from django.contrib import admin
from django.urls import path, include
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/auth/', include('authentication.urls')),
    path('api/companies/', include('companies.urls')),
    path('api/projects/', include('projects.urls')),
    path('api/invitations/', include('invitations.urls')),
    path('api/notifications/', include('notifications.urls')),
    path('api/ai/', include('ai.urls')),
    path('api/tasks/', include('projects.urls_task')),
    path('api/activity/', include('activity.urls')),
    # API docs
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='docs'),
]
