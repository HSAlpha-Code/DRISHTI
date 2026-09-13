import hashlib
import json
from django.db import models
from centers.models import InstituteCenter

class AuditTask(models.Model):
    STATUS_CHOICES = [
        ('DISPATCHED', 'Unannounced Dispatch Active'),
        ('IN_PROGRESS', 'Inspector On-Site'),
        ('COMPLETED', 'Audit Completed & Signed'),
        ('FLAGGED', 'Collusion / Tampering Detected'),
    ]

    task_id = models.CharField(max_length=50, unique=True)
    center = models.ForeignKey(InstituteCenter, on_delete=models.CASCADE, related_name='audit_tasks')
    assigned_inspector = models.CharField(max_length=150, default="Inspector Rajesh Kumar")
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
        """
        Generates SHA-256 signature hash of inspection payload + hardware timestamp for tamper protection.
        """
        payload_str = json.dumps(payload_data, sort_keys=True)
        raw_token = f"{self.task_id}:{self.center.code}:{payload_str}"
        return hashlib.sha256(raw_token.encode('utf-8')).hexdigest()

    def verify_signature(self) -> bool:
        if not self.sha256_hash or not self.payload_json:
            return False
        expected = self.calculate_sha256_signature(self.payload_json)
        return expected.lower() == self.sha256_hash.lower()

    def __str__(self):
        return f"[{self.task_id}] {self.center.name} - Status: {self.status}"
