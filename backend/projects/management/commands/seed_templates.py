from django.core.management.base import BaseCommand
from projects.models import ProjectTemplate

TEMPLATES = [
    {
        'name': 'Lancement produit',
        'description': 'Template pour le lancement d\'un nouveau produit ou service',
        'icon': '🚀',
        'is_public': True,
        'tasks': [
            {'title': 'Définir le concept', 'priority': 'HIGH'},
            {'title': 'Étude de marché', 'priority': 'HIGH'},
            {'title': 'Prototype', 'priority': 'HIGH'},
            {'title': 'Tests utilisateurs', 'priority': 'MEDIUM'},
            {'title': 'Plan de communication', 'priority': 'MEDIUM'},
            {'title': 'Lancement officiel', 'priority': 'HIGH'},
        ],
    },
    {
        'name': 'Événement client',
        'description': 'Organisation d\'un événement client ou séminaire',
        'icon': '🎪',
        'is_public': True,
        'tasks': [
            {'title': 'Définir le budget', 'priority': 'HIGH'},
            {'title': 'Réserver la salle', 'priority': 'HIGH'},
            {'title': 'Envoyer les invitations', 'priority': 'HIGH'},
            {'title': 'Planifier le catering', 'priority': 'MEDIUM'},
            {'title': 'Préparer les goodies', 'priority': 'LOW'},
            {'title': 'Jour J', 'priority': 'HIGH'},
        ],
    },
    {
        'name': 'Développement web',
        'description': 'Template pour un projet de développement web classique',
        'icon': '💻',
        'is_public': True,
        'tasks': [
            {'title': 'Spécifications fonctionnelles', 'priority': 'HIGH'},
            {'title': 'Maquettage UI/UX', 'priority': 'HIGH'},
            {'title': 'Développement backend', 'priority': 'HIGH'},
            {'title': 'Développement frontend', 'priority': 'HIGH'},
            {'title': 'Tests', 'priority': 'HIGH'},
            {'title': 'Mise en production', 'priority': 'CRITICAL'},
        ],
    },
]


class Command(BaseCommand):
    help = 'Seed default project templates'

    def handle(self, *args, **options):
        created = 0
        for data in TEMPLATES:
            _, was_created = ProjectTemplate.objects.get_or_create(
                name=data['name'],
                defaults=data,
            )
            if was_created:
                created += 1
        self.stdout.write(self.style.SUCCESS(f'{created} templates créés.'))
