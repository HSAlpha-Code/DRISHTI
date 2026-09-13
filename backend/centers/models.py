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
        try:
            coords = self.boundary_geojson
            if isinstance(coords, str):
                coords = json.loads(coords)
            
            # GeoJSON coordinates are usually [lng, lat]
            if isinstance(coords, dict) and 'coordinates' in coords:
                poly_coords = coords['coordinates'][0]
            elif isinstance(coords, list):
                poly_coords = coords
            else:
                poly_coords = []
                
            if len(poly_coords) < 3:
                # Fallback to radius distance check from center point
                from geopy.distance import geodesic
                dist = geodesic((lat, lng), (self.latitude, self.longitude)).meters
                return dist <= tolerance_meters

            # Create Shapely Polygon (expects (lng, lat) tuples)
            polygon = Polygon([(p[0], p[1]) for p in poly_coords])
            point = Point(lng, lat)
            
            if polygon.contains(point):
                return True
            
            # Check proximity to boundary in meters (approx 0.001 deg ~ 111m)
            dist_deg = polygon.distance(point)
            dist_meters = dist_deg * 111000.0
            return dist_meters <= tolerance_meters
        except Exception as e:
            # Fallback to direct Euclidean distance threshold
            import math
            d = math.sqrt((lat - self.latitude)**2 + (lng - self.longitude)**2)
            return d <= 0.005 # ~500m fallback

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
