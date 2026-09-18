import random
import time
import json
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.shortcuts import render
from rest_framework.decorators import api_view
from rest_framework.response import Response
from centers.models import InstituteCenter
from ai_engine.stream_processor import ai_engine_instance

@api_view(['GET'])
def api_root(request):
    if 'text/html' in request.META.get('HTTP_ACCEPT', ''):
        centers = InstituteCenter.objects.all()
        centers_list = []
        for c in centers:
            latest_log = c.headcount_logs.order_by('-timestamp').first()
            if not latest_log:
                latest_log = ai_engine_instance.process_center_keyframe(c.id)
            
            snapshot_url = latest_log.frame_snapshot if (latest_log and latest_log.frame_snapshot) else ""

            centers_list.append({
                'id': c.id,
                'name': c.name,
                'code': c.code,
                'district': c.district,
                'state': c.state,
                'latitude': c.latitude,
                'longitude': c.longitude,
                'expected_capacity': c.expected_capacity,
                'current_headcount': c.current_headcount,
                'risk_score': c.risk_score,
                'risk_level': c.risk_level,
                'boundary_geojson': c.boundary_geojson,
                'snapshot_url': snapshot_url
            })
        return render(request, 'api_dashboard.html', {
            'centers': centers,
            'centers_json': json.dumps(centers_list)
        })

    return Response({
        "status": "online",
        "service": "MoSJE CCTV Automated Headcount & Geo-Locked Inspection API",
        "version": "1.0.0",
        "dataset": "Kaggle CCTV Exam Monitor Dataset (8,156 Frames)",
        "endpoints": {
            "centers": "/api/centers/",
            "geojson": "/api/centers/geojson_features/",
            "headcount_logs": "/api/headcount-logs/",
            "audit_tasks": "/api/audit-tasks/",
            "trigger_ai_sample": "/api/ai/trigger/",
            "agora_token": "/api/agora/token/"
        }
    })

@api_view(['POST', 'GET'])
def trigger_ai_sample(request):
    centers = InstituteCenter.objects.all()
    logs = []
    for c in centers:
        log = ai_engine_instance.process_center_keyframe(c.id)
        if log:
            logs.append({
                'center_id': c.id,
                'center_code': c.code,
                'center_name': c.name,
                'detected': log.detected_headcount,
                'expected': log.expected_headcount,
                'risk_score': log.risk_score_snapshot,
                'snapshot_url': log.frame_snapshot
            })
    return Response({"status": "SUCCESS", "processed_centers": len(logs), "samples": logs})

@api_view(['GET', 'POST'])
def agora_token_gen(request):
    """
    Generates Agora WebRTC RTC App Token for spot beneficiary interview video call.
    """
    channel = request.query_params.get('channel', 'mosje_spot_call_001')
    app_id = "mosje_agora_app_id_demo_2026"
    mock_token = f"AGORA_RTC_TOKEN_{channel}_{int(time.time())}_SECURE"
    
    return Response({
        "status": "SUCCESS",
        "app_id": app_id,
        "channel_name": channel,
        "token": mock_token,
        "uid": random.randint(100000, 999999)
    })

urlpatterns = [
    path('', api_root),
    path('admin/', admin.site.urls),
    path('api/', api_root),
    path('api/', include('centers.urls')),
    path('api/', include('attendance.urls')),
    path('api/', include('inspections.urls')),
    path('api/ai/trigger/', trigger_ai_sample),
    path('api/agora/token/', agora_token_gen),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
