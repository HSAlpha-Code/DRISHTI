from rest_framework import serializers
from centers.models import InstituteCenter

class InstituteCenterSerializer(serializers.ModelSerializer):
    class Meta:
        model = InstituteCenter
        fields = '__all__'
