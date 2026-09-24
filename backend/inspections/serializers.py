from rest_framework import serializers
from inspections.models import AuditTask, Inspection, AuditLog

class AuditTaskSerializer(serializers.ModelSerializer):
    center_name = serializers.CharField(source='center.name', read_only=True)
    center_code = serializers.CharField(source='center.code', read_only=True)
    center_district = serializers.CharField(source='center.district', read_only=True)
    center_latitude = serializers.FloatField(source='center.latitude', read_only=True)
    center_longitude = serializers.FloatField(source='center.longitude', read_only=True)

    class Meta:
        model = AuditTask
        fields = '__all__'

class InspectionSerializer(serializers.ModelSerializer):
    organization_name = serializers.CharField(source='organization.name', read_only=True)
    project_name = serializers.CharField(source='project.name', read_only=True)

    class Meta:
        model = Inspection
        fields = '__all__'

class AuditLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = AuditLog
        fields = '__all__'
