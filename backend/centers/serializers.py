from rest_framework import serializers
from centers.models import (
    InstituteCenter, NGOOrganization, Project, Funding, Expense, 
    Beneficiary, Document, Camera, AlertEvent, IssueReport, ProgressReport
)

class InstituteCenterSerializer(serializers.ModelSerializer):
    class Meta:
        model = InstituteCenter
        fields = '__all__'

class FundingSerializer(serializers.ModelSerializer):
    class Meta:
        model = Funding
        fields = '__all__'

class ExpenseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Expense
        fields = '__all__'

class BeneficiarySerializer(serializers.ModelSerializer):
    class Meta:
        model = Beneficiary
        fields = '__all__'

class DocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Document
        fields = '__all__'

class CameraSerializer(serializers.ModelSerializer):
    class Meta:
        model = Camera
        fields = '__all__'

class AlertEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = AlertEvent
        fields = '__all__'

class ProgressReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProgressReport
        fields = '__all__'

class IssueReportSerializer(serializers.ModelSerializer):
    class Meta:
        model = IssueReport
        fields = '__all__'

class ProjectSerializer(serializers.ModelSerializer):
    fundings = FundingSerializer(many=True, read_only=True)
    expenses = ExpenseSerializer(many=True, read_only=True)
    beneficiaries = BeneficiarySerializer(many=True, read_only=True)
    documents = DocumentSerializer(many=True, read_only=True)
    cameras = CameraSerializer(many=True, read_only=True)
    alerts = AlertEventSerializer(many=True, read_only=True)
    remaining_amount = serializers.FloatField(read_only=True)
    utilization_pct = serializers.FloatField(read_only=True)

    class Meta:
        model = Project
        fields = '__all__'

class NGOOrganizationSerializer(serializers.ModelSerializer):
    projects = ProjectSerializer(many=True, read_only=True)
    issues = IssueReportSerializer(many=True, read_only=True)

    class Meta:
        model = NGOOrganization
        fields = '__all__'
