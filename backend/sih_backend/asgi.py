import os
from django.core.asgi import get_asgi_application
from channels.routing import ProtocolTypeRouter, URLRouter
from django.urls import path
from sih_backend.consumers import DashboardConsumer, AgoraWebRTCConsumer

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'sih_backend.settings')

django_asgi_app = get_asgi_application()

websocket_urlpatterns = [
    path('ws/dashboard/', DashboardConsumer.as_asgi()),
    path('ws/call/<str:room_name>/', AgoraWebRTCConsumer.as_asgi()),
]

application = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": URLRouter(websocket_urlpatterns),
})
