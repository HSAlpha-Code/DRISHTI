from django.test import TestCase
from rest_framework.test import APIClient
from centers.models import InstituteCenter
from inspections.models import AuditTask

class AuditTaskTest(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.center = InstituteCenter.objects.create(
            name="Test Institute",
            code="TEST-DEL-002",
            latitude=28.6139,
            longitude=77.2090,
            expected_capacity=50,
            boundary_geojson=[
                [77.2070, 28.6120],
                [77.2110, 28.6120],
                [77.2110, 28.6150],
                [77.2070, 28.6150],
                [77.2070, 28.6120]
            ]
        )
        self.task = AuditTask.objects.create(
            task_id="TASK-TEST-001",
            center=self.center,
            assigned_inspector="Inspector Test",
            trigger_reason="Test Audit"
        )

    def test_sha256_signature_calculation(self):
        payload = {"is_open": True, "headcount": 45}
        signature = self.task.calculate_sha256_signature(payload)
        self.assertEqual(len(signature), 64)

    def test_submit_report_api_outside_boundary(self):
        response = self.client.post(f"/api/audit-tasks/{self.task.id}/submit_signed_report/", {
            "latitude": 30.0000,
            "longitude": 80.0000,
            "payload": {"is_open": True}
        }, format='json')
        self.assertEqual(response.status_code, 403)
        self.assertEqual(response.data.get("error"), "GEO_LOCK_VIOLATION")

    def test_submit_report_api_inside_boundary(self):
        payload = {"is_open": True, "students_present": True}
        sig = self.task.calculate_sha256_signature(payload)
        response = self.client.post(f"/api/audit-tasks/{self.task.id}/submit_signed_report/", {
            "latitude": 28.6130,
            "longitude": 77.2080,
            "payload": payload,
            "sha256_hash": sig
        }, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data.get("status"), "SUCCESS")
        self.assertTrue(response.data.get("hardware_gps_verified"))
