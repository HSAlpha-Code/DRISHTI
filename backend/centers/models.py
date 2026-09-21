import json
from django.db import models
from shapely.geometry import Point, Polygon

class InstituteCenter(models.Model):
    RISK_LEVEL_CHOICES = [
        ('NORMAL', 'Normal'),
        ('ELEVATED', 'Elevated Warning'),
        ('CRITICAL', 'Critical - Unannounced Dispatch'),
    ]

    name = models.CharField(max_length=255)
    code = models.CharField(max_length=50, unique=True)
    district = models.CharField(max_length=100, default='Central District')
    state = models.CharField(max_length=100, default='Delhi')
    latitude = models.FloatField()
    longitude = models.FloatField()
    boundary_geojson = models.JSONField(help_text="Polygon coordinates list [[lng, lat], ...]")
    expected_capacity = models.IntegerField(default=50)
    current_headcount = models.IntegerField(default=0)
    risk_score = models.FloatField(default=0.0)
    risk_level = models.CharField(max_length=20, choices=RISK_LEVEL_CHOICES, default='NORMAL')
    cctv_stream_url = models.CharField(max_length=500, default="sample_feed.mp4")
    last_monitored_at = models.DateTimeField(auto_now=True)

    def is_within_boundary(self, lat: float, lng: float, tolerance_meters: float = 100.0) -> bool:
        """
        Hardware-verified site boundary check using Shapely geometry.
        Returns True if the inspector's hardware GPS coordinate is inside or within tolerance.
        """
        from geopy.distance import geodesic

        try:
            coords = self.boundary_geojson
            if isinstance(coords, str):
                coords = json.loads(coords)
            
            if isinstance(coords, dict) and 'coordinates' in coords:
                coords = coords['coordinates']

            # Unwrap nested rings if present
            while isinstance(coords, list) and len(coords) > 0 and isinstance(coords[0], list) and len(coords[0]) > 0 and isinstance(coords[0][0], list):
                coords = coords[0]

            poly_coords = []
            if isinstance(coords, list):
                for p in coords:
                    if isinstance(p, (list, tuple)) and len(p) >= 2:
                        poly_coords.append((float(p[0]), float(p[1])))

            if len(poly_coords) < 3:
                dist = geodesic((lat, lng), (self.latitude, self.longitude)).meters
                return dist <= tolerance_meters

            # Create Shapely Polygon (expects (lng, lat) tuples)
            polygon = Polygon(poly_coords)
            point = Point(lng, lat)
            
            if polygon.contains(point) or polygon.touches(point):
                return True
            
            # Check proximity to boundary in meters (approx 0.001 deg ~ 111m)
            dist_deg = polygon.distance(point)
            dist_meters = dist_deg * 111000.0
            return dist_meters <= tolerance_meters
        except Exception:
            try:
                dist = geodesic((lat, lng), (self.latitude, self.longitude)).meters
                return dist <= tolerance_meters
            except Exception:
                return False

    def recalculate_risk_score(self, detected_headcount: int):
        """
        Dynamic Risk Score engine based on headcount discrepancy & rolling alerts.
        """
        discrepancy = abs(self.expected_capacity - detected_headcount)
        discrepancy_pct = (discrepancy / max(1, self.expected_capacity)) * 100.0
        
        # Risk score calculation formula:
        # Base risk from discrepancy percentage + penalty for severe low turnout
        base_score = min(100.0, discrepancy_pct * 1.2)
        if detected_headcount < (self.expected_capacity * 0.4):
            base_score = min(100.0, base_score + 25.0)

        # Smooth rolling average (70% current, 30% new score)
        self.risk_score = round(0.7 * self.risk_score + 0.3 * base_score, 1)
        self.current_headcount = detected_headcount

        if self.risk_score >= 65.0:
            self.risk_level = 'CRITICAL'
        elif self.risk_score >= 35.0:
            self.risk_level = 'ELEVATED'
        else:
            self.risk_level = 'NORMAL'
            
        self.save()
        return self.risk_score, self.risk_level

    def __str__(self):
        return f"{self.name} ({self.code}) - Risk: {self.risk_score}% ({self.risk_level})"
