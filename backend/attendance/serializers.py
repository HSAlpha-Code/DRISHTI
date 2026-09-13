from rest_framework import serializers
from attendance.models import HeadcountLog

class HeadcountLogSerializer(serializers.ModelSerializer):
    center_name = serializers.CharField(source='center.name', read_only=True)
    center_code = serializers.CharField(source='center.code', read_only=True)

    class Meta:
        model = HeadcountLog
        fields = '__all__'
