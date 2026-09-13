import json
import random
from channels.generic.websocket import AsyncWebsocketConsumer

class DashboardConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.group_name = 'dashboard_updates'
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()
        
        # Send initial connection confirmation
        await self.send(text_data=json.dumps({
            'type': 'CONNECTION_ESTABLISHED',
            'message': 'Connected to MoSJE CCTV & Audit Dispatch Realtime Stream',
        }))

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def receive(self, text_data):
        data = json.loads(text_data)
        event_type = data.get('type')
        
        if event_type == 'PING':
            await self.send(text_data=json.dumps({'type': 'PONG'}))

    async def dashboard_update(self, event):
        """Handler for events sent to group dashboard_updates."""
        await self.send(text_data=json.dumps(event))


class AgoraWebRTCConsumer(AsyncWebsocketConsumer):
    """
    Signaling channel for WebRTC and Agora Video Call initialization.
    Manages channel names, tokens, and peer call status.
    """
    async def connect(self):
        self.room_name = self.scope['url_route']['kwargs']['room_name']
        self.room_group_name = f'agora_call_{self.room_name}'
        
        await self.channel_layer.group_add(self.room_group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self.channel_layer.group_discard(self.room_group_name, self.channel_name)

    async def receive(self, text_data):
        data = json.loads(text_data)
        msg_type = data.get('type')

        # Broadcast signaling messages (JOIN, OFFER, ANSWER, ICE_CANDIDATE, LEAVE)
        await self.channel_layer.group_send(
            self.room_group_name,
            {
                'type': 'signal_message',
                'sender_channel': self.channel_name,
                'data': data
            }
        )

    async def signal_message(self, event):
        if event['sender_channel'] != self.channel_name:
            await self.send(text_data=json.dumps(event['data']))
