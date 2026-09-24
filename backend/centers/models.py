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
        try:
            coords = self.boundary_geojson
            if isinstance(coords, str):
                coords = json.loads(coords)
            
            if isinstance(coords, dict) and 'coordinates' in coords:
                poly_coords = coords['coordinates'][0]
            elif isinstance(coords, list):
                poly_coords = coords
            else:
                poly_coords = []
                
            if len(poly_coords) < 3:
                from geopy.distance import geodesic
                dist = geodesic((lat, lng), (self.latitude, self.longitude)).meters
                return dist <= tolerance_meters

            polygon = Polygon([(p[0], p[1]) for p in poly_coords])
            point = Point(lng, lat)
            
            if polygon.contains(point):
                return True
            
            dist_deg = polygon.distance(point)
            dist_meters = dist_deg * 111000.0
            return dist_meters <= tolerance_meters
        except Exception:
            import math
            d = math.sqrt((lat - self.latitude)**2 + (lng - self.longitude)**2)
            return d <= 0.005

    def recalculate_risk_score(self, detected_headcount: int):
        discrepancy = abs(self.expected_capacity - detected_headcount)
        discrepancy_pct = (discrepancy / max(1, self.expected_capacity)) * 100.0
        
        base_score = min(100.0, discrepancy_pct * 1.2)
        if detected_headcount < (self.expected_capacity * 0.4):
            base_score = min(100.0, base_score + 25.0)

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


class NGOOrganization(models.Model):
    SECTOR_CHOICES = [
        ('Education', 'Education & Skill Training'),
        ('Healthcare', 'Healthcare & Medical Relief'),
        ('Women Welfare', 'Women Welfare & Empowerment'),
        ('Rural Development', 'Rural Development & Livelihood'),
        ('Environment', 'Environment & Sustainability'),
        ('Disability Support', 'Disability Support & Rehabilitation'),
        ('Elderly Care', 'Senior Citizen Care & Daycare'),
    ]

    VERIFICATION_CHOICES = [
        ('Verified', 'Verified'),
        ('Pending', 'Pending'),
        ('Under Review', 'Under Review'),
    ]

    name = models.CharField(max_length=255)
    registration_id = models.CharField(max_length=50, unique=True, help_text="Format: XXXXX-XXXXX-XXXXX-XXXXX-XXXXX")
    sector = models.CharField(max_length=100, default='Education')
    city = models.CharField(max_length=100)
    state = models.CharField(max_length=100)
    full_address = models.TextField()
    contact_email = models.EmailField()
    contact_phone = models.CharField(max_length=30)
    verification_status = models.CharField(max_length=30, choices=VERIFICATION_CHOICES, default='Verified')
    services_provided = models.JSONField(default=list, blank=True)
    scope_and_facilities = models.JSONField(default=list, blank=True)
    latitude = models.FloatField(default=28.6139)
    longitude = models.FloatField(default=77.2090)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return f"{self.name} ({self.registration_id})"


class Project(models.Model):
    STATUS_CHOICES = [
        ('Active', 'Active'),
        ('Completed', 'Completed'),
        ('Suspended', 'Suspended'),
    ]

    organization = models.ForeignKey(NGOOrganization, on_delete=models.CASCADE, related_name='projects')
    project_id = models.CharField(max_length=50, unique=True)
    name = models.CharField(max_length=255)
    category = models.CharField(max_length=100)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='Active')
    start_date = models.DateField()
    end_date = models.DateField(null=True, blank=True)
    description = models.TextField()
    sanctioned_amount = models.FloatField(default=0.0, help_text="Amount in INR")
    released_amount = models.FloatField(default=0.0)
    spent_amount = models.FloatField(default=0.0)
    beneficiaries_target = models.IntegerField(default=100)
    beneficiaries_registered = models.IntegerField(default=0)
    progress_pct = models.FloatField(default=0.0)

    @property
    def remaining_amount(self):
        return max(0.0, self.released_amount - self.spent_amount)

    @property
    def utilization_pct(self):
        if self.released_amount <= 0:
            return 0.0
        return round((self.spent_amount / self.released_amount) * 100.0, 1)

    def __str__(self):
        return f"{self.name} ({self.project_id})"


class Funding(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='fundings')
    source = models.CharField(max_length=150)
    stage = models.CharField(max_length=50, choices=[('Sanctioned', 'Sanctioned'), ('Released', 'Released')])
    amount = models.FloatField()
    date = models.DateField()
    purpose = models.CharField(max_length=255)
    reference = models.CharField(max_length=100)

    def __str__(self):
        return f"{self.source} - ₹{self.amount} ({self.stage})"


class Expense(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='expenses')
    txn_id = models.CharField(max_length=50, unique=True)
    purpose = models.CharField(max_length=255)
    amount = models.FloatField()
    vendor = models.CharField(max_length=255)
    date = models.DateField()
    status = models.CharField(max_length=30, choices=[('Verified', 'Verified'), ('Pending', 'Pending')], default='Verified')

    def __str__(self):
        return f"{self.txn_id} - ₹{self.amount} to {self.vendor}"


class Beneficiary(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='beneficiaries')
    name = models.CharField(max_length=150)
    age = models.IntegerField()
    gender = models.CharField(max_length=20, choices=[('Male', 'Male'), ('Female', 'Female'), ('Other', 'Other')])
    service_received = models.CharField(max_length=255)
    date = models.DateField()

    def __str__(self):
        return f"{self.name} ({self.gender}, {self.age})"


class Document(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='documents')
    title = models.CharField(max_length=255)
    doc_type = models.CharField(max_length=100)
    file_url = models.CharField(max_length=500)
    file_size = models.CharField(max_length=50, default='1.2 MB')
    uploaded_at = models.DateTimeField(auto_now_add=True)
    sha256_hash = models.CharField(max_length=64, blank=True)

    def __str__(self):
        return f"{self.title} ({self.doc_type})"


class Camera(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='cameras')
    name = models.CharField(max_length=150)
    stream_url = models.CharField(max_length=500)
    status = models.CharField(max_length=20, default='Online')
    last_headcount = models.IntegerField(default=0)
    expected_headcount = models.IntegerField(default=40)
    risk_score = models.FloatField(default=0.0)

    def __str__(self):
        return f"{self.name} - {self.project.name}"


class AlertEvent(models.Model):
    SEVERITY_CHOICES = [
        ('Critical', 'Critical'),
        ('Elevated', 'Elevated'),
        ('Normal', 'Normal'),
    ]
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='alerts')
    severity = models.CharField(max_length=20, choices=SEVERITY_CHOICES, default='Normal')
    reason = models.CharField(max_length=255)
    status = models.CharField(max_length=30, choices=[('Open', 'Open'), ('Resolved', 'Resolved')], default='Open')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"[{self.severity}] {self.reason}"


class IssueReport(models.Model):
    organization = models.ForeignKey(NGOOrganization, on_delete=models.CASCADE, related_name='issues')
    subject = models.CharField(max_length=255)
    description = models.TextField()
    priority = models.CharField(max_length=20, choices=[('High', 'High'), ('Medium', 'Medium'), ('Low', 'Low')], default='Medium')
    status = models.CharField(max_length=30, choices=[('Submitted', 'Submitted'), ('In Review', 'In Review'), ('Resolved', 'Resolved')], default='Submitted')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Issue #{self.id}: {self.subject} ({self.status})"


class ProgressReport(models.Model):
    project = models.ForeignKey(Project, on_delete=models.CASCADE, related_name='progress_reports')
    progress_pct = models.FloatField()
    beneficiaries_served = models.IntegerField()
    notes = models.TextField()
    submitted_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Report {self.project.project_id} - {self.progress_pct}%"
