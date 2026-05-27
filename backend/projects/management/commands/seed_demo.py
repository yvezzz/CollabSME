import random
from datetime import timedelta
from django.utils import timezone
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from companies.models import Company
from projects.models import Project, ProjectMember, Task, Comment, ChecklistItem
from notifications.models import Notification
from activity.models import ActivityLog

User = get_user_model()


class Command(BaseCommand):
    help = "Seed demo data for realistic stats"

    def handle(self, *args, **options):
        company, _ = Company.objects.get_or_create(
            name="CollabSME Demo",
            defaults={
                "website": "https://collabsme-demo.com",
                "billing_email": "billing@collabsme-demo.com",
                "address": "15 Rue de la Paix",
                "city": "Paris",
                "postal_code": "75002",
                "country": "France",
                "subscription_status": "PRO",
            },
        )

        admin_user, _ = User.objects.get_or_create(
            email="admin@demo.com",
            defaults={
                "first_name": "Sophie",
                "last_name": "Martin",
                "company": company,
                "role": "ADMIN",
                "is_company_admin": True,
            },
        )
        admin_user.set_password("Demo1234!")
        admin_user.save()

        members_data = [
            ("lea.dupont@demo.com", "Léa", "Dupont", "LEAD"),
            ("thomas.leroy@demo.com", "Thomas", "Leroy", "MEMBER"),
            ("emma.petit@demo.com", "Emma", "Petit", "MEMBER"),
            ("lucas.bernard@demo.com", "Lucas", "Bernard", "MEMBER"),
            ("chloe.moreau@demo.com", "Chloé", "Moreau", "LEAD"),
        ]
        members = [admin_user]
        for email, fn, ln, role in members_data:
            user, created = User.objects.get_or_create(
                email=email,
                defaults={
                    "first_name": fn,
                    "last_name": ln,
                    "company": company,
                    "role": role,
                    "is_company_admin": role == "ADMIN",
                },
            )
            if created:
                user.set_password("Demo1234!")
                user.save()
            members.append(user)

        projects_data = [
            {
                "title": "Refonte Site Web",
                "key": "RSW",
                "description": "Refonte complète du site vitrine avec nouvelle charte graphique",
                "status": "ACTIVE",
                "priority": "HIGH",
                "budget": 25000,
                "start_date": timezone.now() - timedelta(days=45),
                "end_date": timezone.now() + timedelta(days=30),
            },
            {
                "title": "App Mobile Marketing",
                "key": "AMM",
                "description": "Développement de l'application mobile de campagne marketing",
                "status": "ACTIVE",
                "priority": "HIGH",
                "budget": 45000,
                "start_date": timezone.now() - timedelta(days=20),
                "end_date": timezone.now() + timedelta(days=60),
            },
            {
                "title": "Migration Cloud",
                "key": "MCL",
                "description": "Migration de l'infrastructure vers le cloud AWS",
                "status": "PLANNING",
                "priority": "MEDIUM",
                "budget": 15000,
                "start_date": timezone.now() + timedelta(days=15),
                "end_date": timezone.now() + timedelta(days=90),
            },
            {
                "title": "Campagne SEO Q3",
                "key": "SEO",
                "description": "Optimisation SEO et campagne de contenu pour le troisième trimestre",
                "status": "ACTIVE",
                "priority": "MEDIUM",
                "budget": 8000,
                "start_date": timezone.now() - timedelta(days=10),
                "end_date": timezone.now() + timedelta(days=75),
            },
            {
                "title": "ERP Interne",
                "key": "ERP",
                "description": "Déploiement du nouvel ERP interne pour la gestion des ressources",
                "status": "DRAFT",
                "priority": "LOW",
                "budget": 60000,
                "start_date": None,
                "end_date": None,
            },
            {
                "title": "Rapport Annuel",
                "key": "RAP",
                "description": "Préparation du rapport d'activité annuel",
                "status": "COMPLETED",
                "priority": "HIGH",
                "budget": 3000,
                "start_date": timezone.now() - timedelta(days=90),
                "end_date": timezone.now() - timedelta(days=5),
                "actual_cost": 2800,
            },
            {
                "title": "Application RH",
                "key": "ARH",
                "description": "Développement de l'application interne pour les ressources humaines",
                "status": "ON_HOLD",
                "priority": "MEDIUM",
                "budget": 35000,
                "start_date": timezone.now() - timedelta(days=30),
                "end_date": timezone.now() + timedelta(days=60),
            },
            {
                "title": "Formation Équipe",
                "key": "FOR",
                "description": "Programme de formation continue pour l'équipe technique",
                "status": "ACTIVE",
                "priority": "LOW",
                "budget": 5000,
                "start_date": timezone.now() - timedelta(days=5),
                "end_date": timezone.now() + timedelta(days=25),
            },
        ]
        task_templates = {
            "Refonte Site Web": [
                ("Audit SEO et performance", "DONE", "HIGH", 1),
                ("Maquettage UI/UX", "DONE", "HIGH", 1),
                ("Développement frontend", "IN_PROGRESS", "HIGH", 2),
                ("Développement backend", "IN_PROGRESS", "HIGH", 3),
                ("Tests utilisateurs", "TODO", "MEDIUM", None),
                ("Mise en production", "TODO", "CRITICAL", None),
            ],
            "App Mobile Marketing": [
                ("Spécifications fonctionnelles", "DONE", "HIGH", 1),
                ("Design des écrans", "IN_PROGRESS", "HIGH", 2),
                ("Développement iOS", "TODO", "HIGH", None),
                ("Développement Android", "TODO", "HIGH", None),
                ("Tests bêta", "TODO", "MEDIUM", None),
            ],
            "Campagne SEO Q3": [
                ("Analyse des mots-clés", "DONE", "HIGH", 4),
                ("Rédaction d'articles", "IN_PROGRESS", "MEDIUM", 3),
                ("Optimisation technique", "TODO", "HIGH", None),
                ("Suivi des positions", "IN_PROGRESS", "MEDIUM", 4),
            ],
            "Formation Équipe": [
                ("Sélection des formations", "DONE", "MEDIUM", 0),
                ("Planification des sessions", "IN_PROGRESS", "MEDIUM", 0),
                ("Session Docker & Kubernetes", "TODO", "HIGH", None),
                ("Session CI/CD", "TODO", "MEDIUM", None),
            ],
        }

        for p_data in projects_data:
            proj, _ = Project.objects.get_or_create(
                title=p_data["title"],
                defaults={
                    "key": p_data["key"],
                    "company": company,
                    "description": p_data["description"],
                    "status": p_data["status"],
                    "priority": p_data["priority"],
                    "budget": p_data["budget"],
                    "actual_cost": p_data.get("actual_cost", 0),
                    "start_date": p_data["start_date"],
                    "end_date": p_data["end_date"],
                    "created_by": admin_user,
                },
            )

            for m in members[:random.randint(2, len(members))]:
                ProjectMember.objects.get_or_create(project=proj, user=m, defaults={"role": m.role})

            templates = task_templates.get(proj.title, [])
            for i, (title, status, priority, assignee_idx) in enumerate(templates):
                assigned = members[assignee_idx] if assignee_idx is not None and assignee_idx < len(members) else None
                due = proj.end_date or (timezone.now() + timedelta(days=30))
                task = Task.objects.create(
                    project=proj,
                    title=title,
                    status=status,
                    priority=priority,
                    assigned_to=assigned,
                    created_by=admin_user,
                    order=i,
                    due_date=due if random.random() > 0.3 else None,
                )

                if status == "DONE":
                    ActivityLog.objects.create(
                        company=company,
                        actor=admin_user,
                        action_type="TASK_UPDATED",
                        target_description=f"Tâche '{title}' terminée dans {proj.title}",
                    )

            extra_tasks = 0
            for _ in range(random.randint(0, 3)):
                extra_tasks += 1
                Task.objects.create(
                    project=proj,
                    title=f"Tâche supplémentaire #{extra_tasks}",
                    status=random.choice(["TODO", "IN_PROGRESS", "REVIEW"]),
                    priority=random.choice(["LOW", "MEDIUM", "HIGH"]),
                    assigned_to=random.choice(members),
                    created_by=admin_user,
                    order=10 + extra_tasks,
                )

            ActivityLog.objects.create(
                company=company,
                actor=admin_user,
                action_type="PROJECT_CREATED",
                target_description=f"Projet '{proj.title}' créé",
            )

        now = timezone.now()
        for i in range(5):
            Notification.objects.create(
                user=random.choice(members),
                title="Rappel d'échéance",
                message=f"La tâche approche de sa date limite.",
                notification_type="TASK_ASSIGNED",
                is_read=i < 2,
            )

        for i in range(3):
            Notification.objects.create(
                user=random.choice(members),
                title="Membre ajouté",
                message=f"Un nouveau membre a rejoint votre projet.",
                notification_type="INVITATION_ACCEPTED",
                is_read=False,
            )

        self.stdout.write(self.style.SUCCESS(
            f"✅ Données de démo injectées :\n"
            f"   • {User.objects.filter(company=company).count()} utilisateurs\n"
            f"   • {Project.objects.filter(company=company).count()} projets\n"
            f"   • {Task.objects.filter(project__company=company).count()} tâches\n"
            f"   • {Notification.objects.count()} notifications\n"
            f"   • {ActivityLog.objects.filter(company=company).count()} activités\n"
            f"\n👤 Admin : admin@demo.com / Demo1234!"
        ))
