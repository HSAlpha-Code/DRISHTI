from rest_framework import viewsets
from attendance.models import HeadcountLog
from attendance.serializers import HeadcountLogSerializer

class HeadcountLogViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = HeadcountLog.objects.all()
    serializer_class = HeadcountLogSerializer
