import json
import logging

from channels.generic.websocket import AsyncJsonWebsocketConsumer
from channels.db import database_sync_to_async

from rest_framework_simplejwt.tokens import AccessToken

logger = logging.getLogger(__name__)


class NotificationConsumer(AsyncJsonWebsocketConsumer):
    async def connect(self):
        self.user = None
        token = self.scope.get('query_string', b'').decode()

        if token.startswith('token='):
            token = token.replace('token=', '', 1)

        if token:
            try:
                access_token = AccessToken(token)
                user_id = access_token['user_id']

                from django.contrib.auth import get_user_model
                User = get_user_model()
                self.user = await database_sync_to_async(User.objects.get)(id=user_id)
            except Exception as e:
                logger.warning(f'WebSocket auth failed: {e}')
                await self.close()
                return

        if self.user is None:
            await self.close()
            return

        self.group_name = f'notifications_{self.user.id}'
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()
        logger.info(f'WebSocket connected: user={self.user.email}')

    async def disconnect(self, close_code):
        if hasattr(self, 'group_name'):
            await self.channel_layer.group_discard(
                self.group_name, self.channel_name
            )

    async def receive_json(self, content):
        pass

    async def send_notification(self, event):
        await self.send_json(event['data'])


# Helper function to send notification via channel layer
async def send_notification_to_user(user_id, notification_data):
    from channels.layers import get_channel_layer
    channel_layer = get_channel_layer()
    group_name = f'notifications_{user_id}'
    await channel_layer.group_send(
        group_name,
        {
            'type': 'send_notification',
            'data': {
                'type': 'notification',
                'notification': notification_data,
            },
        },
    )
