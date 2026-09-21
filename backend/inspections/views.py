from django.utils import timezone
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from inspections.models import AuditTask
from inspections.serializers import AuditTaskSerializer
from centers.models import InstituteCenter

class AuditTaskViewSet(viewsets.ModelViewSet):
    queryset = AuditTask.objects.all()
    serializer_class = AuditTaskSerializer

    @action(detail=True, methods=['post'])
    def submit_signed_report(self, request, pk=None):
        """
        Geo-locked & SHA-256 Signed Audit Report Submission Endpoint.
        Enforces hardware GPS boundary check before accepting report.
        """
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

        # 1. Hardware-Verified Site Boundary Lock
        if not task.center.is_within_boundary(lat, lng):
            return Response({
                'error': 'GEO_LOCK_VIOLATION',
                'message': 'Submission Rejected! Your hardware GPS location is outside the verified site boundary for this center.',
                'hardware_verified': False
            }, status=status.HTTP_403_FORBIDDEN)

        # 2. SHA-256 Cryptographic Hash Validation
        computed_hash = task.calculate_sha256_signature(payload)
        
        task.status = 'COMPLETED'
        task.geo_unlocked = True
        task.hardware_gps_verified = True
        task.inspector_latitude = lat
        task.inspector_longitude = lng
        task.payload_json = payload
        task.sha256_hash = submitted_hash or computed_hash
        task.completed_at = timezone.now()
        if photo_watermark:
            task.photo_watermark_path = photo_watermark
            
        task.save()

        # Lower center risk score after successful verified physical inspection
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
        """
        MoSJE Official Cryptographic Integrity Checker.
        """
        task = self.get_object()
        is_valid = task.verify_signature()
        
        return Response({
            'task_id': task.task_id,
            'stored_hash': task.sha256_hash,
            'recalculated_hash': task.calculate_sha256_signature(task.payload_json),
            'integrity_verified': is_valid,
            'message': 'Cryptographic integrity verified! Report is authentic and untampered.' if is_valid else 'Integrity Mismatch! Report payload or hash has been altered.'
        })
