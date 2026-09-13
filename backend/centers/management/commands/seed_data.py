from django.core.management.base import BaseCommand
from centers.models import InstituteCenter
from inspections.models import AuditTask
import random

class Command(BaseCommand):
    help = 'Seeds initial Institute Centers with PostGIS site boundary polygons and sample Audit Tasks'

    def handle(self, *args, **kwargs):
        self.stdout.write("Seeding MoSJE Institute Centers and GIS boundaries...")
        
        # Center 1: PM-DAKSH Delhi
        c1, _ = InstituteCenter.objects.get_or_create(
            code='MOSJE-DEL-001',
            defaults={
                'name': 'PM-DAKSH Skill Training Institute',
                'district': 'Central Delhi',
                'state': 'Delhi',
                'latitude': 28.6139,
                'longitude': 77.2090,
                'expected_capacity': 60,
                'current_headcount': 54,
                'risk_score': 12.0,
                'risk_level': 'NORMAL',
                'cctv_stream_url': 'cctv_stream_del_01.mp4',
                'boundary_geojson': [
                    [77.2070, 28.6120],
                    [77.2110, 28.6120],
                    [77.2110, 28.6150],
                    [77.2070, 28.6150],
                    [77.2070, 28.6120]
                ]
            }
        )

        # Center 2: NISD Dwarka Delhi (Flagged Center with High Risk Score & Active Dispatch)
        c2, _ = InstituteCenter.objects.get_or_create(
            code='MOSJE-DEL-002',
            defaults={
                'name': 'National Institute of Social Defence',
                'district': 'South West Delhi',
                'state': 'Delhi',
                'latitude': 28.5921,
                'longitude': 77.0460,
                'expected_capacity': 45,
                'current_headcount': 12, # Major Headcount Discrepancy!
                'risk_score': 78.5,
                'risk_level': 'CRITICAL',
                'cctv_stream_url': 'cctv_stream_del_02.mp4',
                'boundary_geojson': [
                    [77.0440, 28.5900],
                    [77.0480, 28.5900],
                    [77.0480, 28.5940],
                    [77.0440, 28.5940],
                    [77.0440, 28.5900]
                ]
            }
        )

        # Center 3: Welfare Center Mumbai
        c3, _ = InstituteCenter.objects.get_or_create(
            code='MOSJE-MUM-003',
            defaults={
                'name': 'Senior Citizen Welfare & Support Center',
                'district': 'Mumbai Suburban',
                'state': 'Maharashtra',
                'latitude': 19.0596,
                'longitude': 72.8406,
                'expected_capacity': 50,
                'current_headcount': 38,
                'risk_score': 42.0,
                'risk_level': 'ELEVATED',
                'cctv_stream_url': 'cctv_stream_mum_03.mp4',
                'boundary_geojson': [
                    [72.8386, 19.0576],
                    [72.8426, 19.0576],
                    [72.8426, 19.0616],
                    [72.8386, 19.0616],
                    [72.8386, 19.0576]
                ]
            }
        )

        # Center 4: Divyangjan Center Bengaluru
        c4, _ = InstituteCenter.objects.get_or_create(
            code='MOSJE-BLR-004',
            defaults={
                'name': 'Divyangjan Rehabilitation & Empowerment Center',
                'district': 'Bengaluru Urban',
                'state': 'Karnataka',
                'latitude': 12.9784,
                'longitude': 77.6408,
                'expected_capacity': 40,
                'current_headcount': 39,
                'risk_score': 8.5,
                'risk_level': 'NORMAL',
                'cctv_stream_url': 'cctv_stream_blr_04.mp4',
                'boundary_geojson': [
                    [77.6388, 12.9764],
                    [77.6428, 12.9764],
                    [77.6428, 12.9804],
                    [77.6388, 12.9804],
                    [77.6388, 12.9764]
                ]
            }
        )

        # Seed initial unannounced audit dispatch task for MOSJE-DEL-002
        task, created = AuditTask.objects.get_or_create(
            task_id='TASK-MOSJE-8821',
            defaults={
                'center': c2,
                'assigned_inspector': 'Inspector Rajesh V. (Flying Squad)',
                'status': 'DISPATCHED',
                'trigger_reason': 'Automated CCTV Discrepancy: Only 12 of 45 expected present. Risk Score spiked to 78.5%',
            }
        )

        self.stdout.write(self.style.SUCCESS("Successfully seeded 4 centers and initial audit task."))
