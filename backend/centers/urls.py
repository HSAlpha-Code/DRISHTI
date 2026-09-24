from rest_framework.routers import DefaultRouter
from centers.views import (
    InstituteCenterViewSet, NGOOrganizationViewSet, ProjectViewSet,
    FundingViewSet, ExpenseViewSet, BeneficiaryViewSet, DocumentViewSet,
    CameraViewSet, AlertEventViewSet, IssueReportViewSet, ProgressReportViewSet
)

router = DefaultRouter()
router.register(r'centers', InstituteCenterViewSet, basename='center')
router.register(r'ngos', NGOOrganizationViewSet, basename='ngo')
router.register(r'projects', ProjectViewSet, basename='project')
router.register(r'fundings', FundingViewSet, basename='funding')
router.register(r'expenses', ExpenseViewSet, basename='expense')
router.register(r'beneficiaries', BeneficiaryViewSet, basename='beneficiary')
router.register(r'documents', DocumentViewSet, basename='document')
router.register(r'cameras', CameraViewSet, basename='camera')
router.register(r'alerts', AlertEventViewSet, basename='alert')
router.register(r'issues', IssueReportViewSet, basename='issue')
router.register(r'progress-reports', ProgressReportViewSet, basename='progress-report')

urlpatterns = router.urls
