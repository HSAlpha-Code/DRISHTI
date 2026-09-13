from rest_framework.routers import DefaultRouter
from inspections.views import AuditTaskViewSet

router = DefaultRouter()
router.register(r'audit-tasks', AuditTaskViewSet, basename='audit-task')

urlpatterns = router.urls
