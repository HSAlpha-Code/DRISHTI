import hashlib
import json
from django.db import models
from centers.models import InstituteCenter, NGOOrganization, Project

class AuditTask(models.Model):
    STATUS_CHOICES = [
        ('DISPATCHED', 'Unannounced Dispatch Active'),
        ('IN_PROGRESS', 'Inspector On-Site'),
        ('COMPLETED', 'Audit Completed & Signed'),
        ('FLAGGED', 'Collusion / Tampering Detected'),
    ]

    task_id = models.CharField(max_length=50, unique=True)
    center = models.ForeignKey(InstituteCenter, on_delete=models.CASCADE, related_name='audit_tasks', null=True, blank=True)
    organization = models.ForeignKey(NGOOrganization, on_delete=models.SET_NULL, related_name='audit_tasks', null=True, blank=True)
    project = models.ForeignKey(Project, on_delete=models.SET_NULL, related_name='audit_tasks', null=True, blank=True)
    assigned_inspector = models.CharField(max_length=150, default="Inspector Rajesh V.")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='DISPATCHED')
    trigger_reason = models.CharField(max_length=255)
    dispatched_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    # Geo-Locking fields
    geo_unlocked = models.BooleanField(default=False)
    inspector_latitude = models.FloatField(null=True, blank=True)
    inspector_longitude = models.FloatField(null=True, blank=True)
    hardware_gps_verified = models.BooleanField(default=False)

    # Payload & Cryptographic verification
    payload_json = models.JSONField(default=dict, blank=True)
    sha256_hash = models.CharField(max_length=64, blank=True, null=True, help_text="Local SHA-256 report signature")
    photo_watermark_path = models.CharField(max_length=500, blank=True, null=True)

    class Meta:
        ordering = ['-dispatched_at']

    def calculate_sha256_signature(self, payload_data: dict) -> str:
        payload_str = json.dumps(payload_data, sort_keys=True)
        raw_token = f"{self.task_id}:{payload_str}"
        return hashlib.sha256(raw_token.encode('utf-8')).hexdigest()

    def verify_signature(self) -> bool:
        if not self.sha256_hash or not self.payload_json:
            return False
        expected = self.calculate_sha256_signature(self.payload_json)
        return expected.lower() == self.sha256_hash.lower()

    def __str__(self):
        return f"[{self.task_id}] {self.trigger_reason} - Status: {self.status}"


class Inspection(models.Model):
    STATUS_CHOICES = [
        ('Assigned', 'Assigned'),
        ('In Progress', 'In Progress'),
        ('Submitted', 'Submitted'),
        ('Reviewed', 'Reviewed'),
    ]
    RESULT_CHOICES = [
        ('Verified', 'Verified'),
        ('Partially Verified', 'Partially Verified'),
        ('Requires Further Action', 'Requires Further Action'),
        ('—', '—'),
    ]
    GOVT_REVIEW_CHOICES = [
        ('Pending', 'Pending'),
        ('Verified', 'Verified'),
        ('Requires Further Action', 'Requires Further Action'),
    ]

    inspection_id = models.CharField(max_length=50, unique=True)
    organization = models.ForeignKey(NGOOrganization, on_delete=models.CASCADE, related_name='inspections')
    project = models.ForeignKey(Project, on_delete=models.SET_NULL, null=True, blank=True, related_name='inspections')
    assigned_inspector = models.CharField(max_length=150, default="Inspector Rajesh V.")
    status = models.CharField(max_length=30, choices=STATUS_CHOICES, default='Assigned')
    overall_result = models.CharField(max_length=40, choices=RESULT_CHOICES, default='—')
    government_review = models.CharField(max_length=40, choices=GOVT_REVIEW_CHOICES, default='Pending')
    assigned_date = models.DateField()
    submitted_date = models.DateField(null=True, blank=True)
    reason = models.CharField(max_length=255)
    
    # Inspection GPS & timing
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    captured_timestamp = models.DateTimeField(null=True, blank=True)
    
    # Checklist and evidence
    checklist_results = models.JSONField(default=dict, blank=True)
    photo_watermark_data = models.JSONField(default=dict, blank=True)
    photo_url = models.CharField(max_length=500, blank=True, null=True)
    observations = models.TextField(blank=True, default='')
    sha256_hash = models.CharField(max_length=64, blank=True, null=True)

    class Meta:
        ordering = ['-assigned_date']

    def __str__(self):
        return f"{self.inspection_id} - {self.organization.name} ({self.status})"


class AuditLog(models.Model):
    ROLE_CHOICES = [
        ('Admin', 'Admin'),
        ('Inspector', 'Inspector'),
        ('NGO Officer', 'NGO Officer'),
    ]

    user = models.CharField(max_length=150)
    role = models.CharField(max_length=50, choices=ROLE_CHOICES)
    action = models.CharField(max_length=255)
    entity = models.CharField(max_length=255)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.timestamp.strftime('%Y-%m-%d %H:%M')} [{self.role}] {self.user}: {self.action} on {self.entity}"
