from django.test import TestCase
from centers.models import InstituteCenter

class InstituteCenterModelTest(TestCase):
    def setUp(self):
        self.center = InstituteCenter.objects.create(
            name="Test Institute",
            code="TEST-DEL-001",
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

    def test_center_creation(self):
        self.assertEqual(self.center.code, "TEST-DEL-001")
        self.assertEqual(self.center.risk_level, "NORMAL")

    def test_is_within_boundary(self):
        # Coordinates inside the box
        inside = self.center.is_within_boundary(28.6130, 77.2080)
        self.assertTrue(inside)

        # Coordinates far outside
        outside = self.center.is_within_boundary(29.0000, 78.0000)
        self.assertFalse(outside)

    def test_recalculate_risk_score(self):
        score, level = self.center.recalculate_risk_score(10) # First calculation with 0 initial risk score
        self.assertEqual(score, 30.0)
        self.assertEqual(self.center.current_headcount, 10)

        # Second calculation rolls up toward base score
        score, level = self.center.recalculate_risk_score(10)
        self.assertGreater(score, 50.0)
