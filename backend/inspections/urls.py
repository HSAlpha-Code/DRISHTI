from rest_framework.routers import DefaultRouter
from inspections.views import AuditTaskViewSet, InspectionViewSet, AuditLogViewSet

router = DefaultRouter()
router.register(r'audit-tasks', AuditTaskViewSet, basename='audit-task')
router.register(r'inspections', InspectionViewSet, basename='inspection')
router.register(r'audit-logs', AuditLogViewSet, basename='audit-log')

urlpatterns = router.urls
