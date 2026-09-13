from django.db import models
from centers.models import InstituteCenter

class HeadcountLog(models.Model):
    center = models.ForeignKey(InstituteCenter, on_delete=models.CASCADE, related_name='headcount_logs')
    timestamp = models.DateTimeField(auto_now_add=True)
    detected_headcount = models.IntegerField()
    expected_headcount = models.IntegerField()
    discrepancy = models.IntegerField()
    risk_score_snapshot = models.FloatField()
    frame_snapshot = models.CharField(max_length=500, blank=True, null=True)
    alert_triggered = models.BooleanField(default=False)

    class Meta:
        ordering = ['-timestamp']

    def __str__(self):
        return f"{self.center.code} - {self.timestamp.strftime('%H:%M:%S')}: Count={self.detected_headcount}/{self.expected_headcount}"
