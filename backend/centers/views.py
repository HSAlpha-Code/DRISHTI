from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from centers.models import (
    InstituteCenter, NGOOrganization, Project, Funding, Expense, 
    Beneficiary, Document, Camera, AlertEvent, IssueReport, ProgressReport
)
from centers.serializers import (
    InstituteCenterSerializer, NGOOrganizationSerializer, ProjectSerializer,
    FundingSerializer, ExpenseSerializer, BeneficiarySerializer, DocumentSerializer,
    CameraSerializer, AlertEventSerializer, IssueReportSerializer, ProgressReportSerializer
)

class InstituteCenterViewSet(viewsets.ModelViewSet):
    queryset = InstituteCenter.objects.all()
    serializer_class = InstituteCenterSerializer

    @action(detail=False, methods=['get'])
    def geojson_features(self, request):
        centers = self.get_queryset()
        features = []
        for c in centers:
            features.append({
                "type": "Feature",
                "geometry": {
                    "type": "Polygon",
                    "coordinates": [c.boundary_geojson] if isinstance(c.boundary_geojson, list) and len(c.boundary_geojson) > 0 and isinstance(c.boundary_geojson[0], list) else [[
                        [c.longitude - 0.002, c.latitude - 0.002],
                        [c.longitude + 0.002, c.latitude - 0.002],
                        [c.longitude + 0.002, c.latitude + 0.002],
                        [c.longitude - 0.002, c.latitude + 0.002],
                        [c.longitude - 0.002, c.latitude - 0.002],
                    ]]
                },
                "properties": {
                    "id": c.id,
                    "name": c.name,
                    "code": c.code,
                    "district": c.district,
                    "state": c.state,
                    "latitude": c.latitude,
                    "longitude": c.longitude,
                    "capacity": c.expected_capacity,
                    "current_headcount": c.current_headcount,
                    "risk_score": c.risk_score,
                    "risk_level": c.risk_level,
                    "cctv_stream_url": c.cctv_stream_url,
                }
            })

        return Response({
            "type": "FeatureCollection",
            "features": features
        })

    @action(detail=True, methods=['post'])
    def verify_gps_boundary(self, request, pk=None):
        center = self.get_object()
        lat = request.data.get('latitude')
        lng = request.data.get('longitude')

        if lat is None or lng is None:
            return Response({'error': 'Latitude and Longitude are required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            lat = float(lat)
            lng = float(lng)
        except ValueError:
            return Response({'error': 'Invalid float coordinate'}, status=status.HTTP_400_BAD_REQUEST)

        is_inside = center.is_within_boundary(lat, lng)

        return Response({
            'center_code': center.code,
            'center_name': center.name,
            'inspector_gps': {'latitude': lat, 'longitude': lng},
            'boundary_verified': is_inside,
            'unlocked': is_inside,
            'message': 'Inspector GPS verified within site boundary.' if is_inside else 'GPS Hardware verification failed. You are outside the designated site boundary.'
        })


class NGOOrganizationViewSet(viewsets.ModelViewSet):
    queryset = NGOOrganization.objects.all().prefetch_related('projects')
    serializer_class = NGOOrganizationSerializer


class ProjectViewSet(viewsets.ModelViewSet):
    queryset = Project.objects.all().prefetch_related('fundings', 'expenses', 'beneficiaries', 'documents', 'cameras', 'alerts')
    serializer_class = ProjectSerializer


class FundingViewSet(viewsets.ModelViewSet):
    queryset = Funding.objects.all()
    serializer_class = FundingSerializer


class ExpenseViewSet(viewsets.ModelViewSet):
    queryset = Expense.objects.all()
    serializer_class = ExpenseSerializer


class BeneficiaryViewSet(viewsets.ModelViewSet):
    queryset = Beneficiary.objects.all()
    serializer_class = BeneficiarySerializer


class DocumentViewSet(viewsets.ModelViewSet):
    queryset = Document.objects.all()
    serializer_class = DocumentSerializer


class CameraViewSet(viewsets.ModelViewSet):
    queryset = Camera.objects.all()
    serializer_class = CameraSerializer


class AlertEventViewSet(viewsets.ModelViewSet):
    queryset = AlertEvent.objects.all()
    serializer_class = AlertEventSerializer


class IssueReportViewSet(viewsets.ModelViewSet):
    queryset = IssueReport.objects.all()
    serializer_class = IssueReportSerializer


class ProgressReportViewSet(viewsets.ModelViewSet):
    queryset = ProgressReport.objects.all()
    serializer_class = ProgressReportSerializer
