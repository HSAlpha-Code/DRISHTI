from rest_framework.routers import DefaultRouter
from attendance.views import HeadcountLogViewSet

router = DefaultRouter()
router.register(r'headcount-logs', HeadcountLogViewSet, basename='headcount-log')

urlpatterns = router.urls
