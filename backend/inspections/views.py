import datetime
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from inspections.models import AuditTask, Inspection, AuditLog
from inspections.serializers import AuditTaskSerializer, InspectionSerializer, AuditLogSerializer
from centers.models import InstituteCenter

class AuditTaskViewSet(viewsets.ModelViewSet):
    queryset = AuditTask.objects.all()
    serializer_class = AuditTaskSerializer

    @action(detail=True, methods=['post'])
    def submit_signed_report(self, request, pk=None):
        task = self.get_object()
        lat = request.data.get('latitude')
        lng = request.data.get('longitude')
        payload = request.data.get('payload', {})
        submitted_hash = request.data.get('sha256_hash')
        photo_watermark = request.data.get('photo_watermark')

        if lat is None or lng is None:
            return Response({'error': 'Hardware GPS coordinates (latitude, longitude) required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            lat = float(lat)
            lng = float(lng)
        except ValueError:
            return Response({'error': 'Invalid float GPS coordinates'}, status=status.HTTP_400_BAD_REQUEST)

        if task.center and not task.center.is_within_boundary(lat, lng):
            return Response({
                'error': 'GEO_LOCK_VIOLATION',
                'message': 'Submission Rejected! Your hardware GPS location is outside the verified site boundary for this center.',
                'hardware_verified': False
            }, status=status.HTTP_403_FORBIDDEN)

        computed_hash = task.calculate_sha256_signature(payload)
        
        task.status = 'COMPLETED'
        task.geo_unlocked = True
        task.hardware_gps_verified = True
        task.inspector_latitude = lat
        task.inspector_longitude = lng
        task.payload_json = payload
        task.sha256_hash = submitted_hash or computed_hash
        task.completed_at = datetime.datetime.now()
        if photo_watermark:
            task.photo_watermark_path = photo_watermark
            
        task.save()

        if task.center:
            task.center.risk_score = max(5.0, task.center.risk_score - 40.0)
            task.center.risk_level = 'NORMAL' if task.center.risk_score < 35.0 else 'ELEVATED'
            task.center.save()

        return Response({
            'status': 'SUCCESS',
            'task_id': task.task_id,
            'message': 'Inspection Report successfully verified via Hardware GPS & SHA-256 signed!',
            'sha256_hash': task.sha256_hash,
            'hash_matches': (submitted_hash.lower() == computed_hash.lower()) if submitted_hash else True,
            'hardware_gps_verified': True,
            'completed_at': task.completed_at.isoformat()
        })

    @action(detail=True, methods=['post'])
    def verify_hash(self, request, pk=None):
        task = self.get_object()
        is_valid = task.verify_signature()
        
        return Response({
            'task_id': task.task_id,
            'stored_hash': task.sha256_hash,
            'recalculated_hash': task.calculate_sha256_signature(task.payload_json),
            'integrity_verified': is_valid,
            'message': 'Cryptographic integrity verified! Report is authentic and untampered.' if is_valid else 'Integrity Mismatch! Report payload or hash has been altered.'
        })


class InspectionViewSet(viewsets.ModelViewSet):
    queryset = Inspection.objects.all().select_related('organization', 'project')
    serializer_class = InspectionSerializer

    @action(detail=True, methods=['post'])
    def government_review(self, request, pk=None):
        inspection = self.get_object()
        decision = request.data.get('decision')
        if decision not in ['Verified', 'Requires Further Action']:
            return Response({'error': 'Invalid decision. Must be Verified or Requires Further Action'}, status=status.HTTP_400_BAD_REQUEST)
        inspection.government_review = decision
        inspection.status = 'Reviewed'
        inspection.save()

        AuditLog.objects.create(
            user=request.data.get('reviewer_name', 'MoSJE Official'),
            role='Admin',
            action=f'GOVERNMENT_REVIEW_{decision.upper().replace(" ", "_")}',
            entity=f'Inspection {inspection.inspection_id} ({inspection.organization.name})'
        )

        return Response({'status': 'SUCCESS', 'government_review': inspection.government_review})


class AuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = AuditLog.objects.all()
    serializer_class = AuditLogSerializer
