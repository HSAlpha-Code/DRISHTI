from rest_framework.routers import DefaultRouter
from centers.views import InstituteCenterViewSet

router = DefaultRouter()
router.register(r'centers', InstituteCenterViewSet, basename='center')

urlpatterns = router.urls
