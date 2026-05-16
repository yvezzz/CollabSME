import json
import logging
import os

import requests
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response

from .models import AIChat
from .serializers import AIChatSerializer

logger = logging.getLogger(__name__)

OPENROUTER_API_KEY = os.environ.get('OPENROUTER_API_KEY', '')
OPENROUTER_MODEL = os.environ.get('OPENROUTER_MODEL', 'z-ai/glm-4.5-air:free')
OPENROUTER_URL = 'https://openrouter.ai/api/v1/chat/completions'

SYSTEM_PROMPT = """Tu es un assistant IA spécialisé en gestion de projet. 
Tu aides les équipes à organiser leur travail, suggérer des tâches, 
et améliorer leur productivité. Réponds en français."""


def call_openrouter(messages):
    if not OPENROUTER_API_KEY:
        return None, "Clé API OpenRouter non configurée."

    headers = {
        'Authorization': f'Bearer {OPENROUTER_API_KEY}',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://koda.app',
    }
    payload = {
        'model': OPENROUTER_MODEL,
        'messages': messages,
        'max_tokens': 1024,
    }

    try:
        resp = requests.post(
            OPENROUTER_URL, headers=headers, json=payload, timeout=30
        )
        resp.raise_for_status()
        data = resp.json()
        return data['choices'][0]['message']['content'], None
    except requests.exceptions.Timeout:
        return None, "Le service IA ne répond pas (timeout)."
    except Exception as e:
        logger.error(f'OpenRouter error: {e}')
        return None, "Erreur du service IA."


@api_view(['POST'])
def chat(request):
    message = request.data.get('message', '')
    if not message:
        return Response({'error': 'Message requis.'}, status=400)

    # Save user message
    AIChat.objects.create(
        user=request.user,
        role='user',
        content=message,
        model_used=OPENROUTER_MODEL,
    )

    # Build conversation history
    history = AIChat.objects.filter(user=request.user).order_by('-created_at')[:20]
    history = list(reversed(history))

    messages = [{'role': 'system', 'content': SYSTEM_PROMPT}]
    for msg in history:
        messages.append({'role': msg.role, 'content': msg.content})

    # Call OpenRouter
    response_text, error = call_openrouter(messages)
    if error:
        response_text = error

    # Save assistant response
    AIChat.objects.create(
        user=request.user,
        role='assistant',
        content=response_text,
        model_used=OPENROUTER_MODEL,
    )

    return Response({'response': response_text})


@api_view(['GET'])
def chat_history(request):
    chats = AIChat.objects.filter(user=request.user)
    limit = int(request.query_params.get('limit', 50))
    chats = chats.order_by('-created_at')[:limit]
    return Response(AIChatSerializer(reversed(chats), many=True).data)


@api_view(['DELETE'])
def clear_chat_history(request):
    AIChat.objects.filter(user=request.user).delete()
    return Response(status=204)


@api_view(['POST'])
def generate_task(request):
    title = request.data.get('title', '')
    project_id = request.data.get('project_id', '')

    if not title:
        return Response({'error': 'Titre requis.'}, status=400)

    messages = [
        {'role': 'system', 'content': SYSTEM_PROMPT},
        {'role': 'user', 'content': (
            f'Génère une description détaillée et des sous-tâches pour '
            f'la tâche suivante: "{title}". '
            f'Réponds au format JSON avec "description" et "subtasks" (liste de strings).'
        )},
    ]

    response_text, error = call_openrouter(messages)
    if error:
        return Response({'error': error}, status=503)

    try:
        result = json.loads(response_text)
    except json.JSONDecodeError:
        result = {'description': response_text, 'subtasks': []}

    return Response(result)


@api_view(['POST'])
def summarize_project(request):
    project_id = request.data.get('project_id', '')

    try:
        from projects.models import Project
        project = Project.objects.get(id=project_id, company=request.user.company)
    except Exception:
        return Response({'error': 'Projet introuvable.'}, status=404)

    tasks = project.tasks.all()
    total = tasks.count()
    done = tasks.filter(status='DONE').count()
    pct = done / total * 100 if total > 0 else 0

    messages = [
        {'role': 'system', 'content': SYSTEM_PROMPT},
        {'role': 'user', 'content': (
            f'Résume le projet "{project.title}" avec {total} tâches '
            f'dont {done} terminées ({pct:.0f}%). '
            f'Donne un résumé concis en français.'
        )},
    ]

    response_text, error = call_openrouter(messages)
    if error:
        return Response({'error': error}, status=503)

    return Response({'summary': response_text})
