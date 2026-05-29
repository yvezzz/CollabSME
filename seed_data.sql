-- ============================================================
-- COLLABSME DATA SEEDING — 29 Mai 2026
-- Ne supprime AUCUNE donnée existante, enrichit uniquement
-- ============================================================

BEGIN;

-- ============================================================
-- 1. ENTREPRISE — Compléter les champs vides
-- ============================================================
UPDATE companies SET
  name           = 'CollabSME Solutions',
  phone          = '+237 699 123 456',
  billing_email  = 'facturation@collabsme.com',
  nif            = 'C123456789',
  address        = '1245 Boulevard de la Liberté',
  city           = 'Douala',
  postal_code    = '00237',
  country        = 'Cameroun',
  website        = 'https://collabsme.com',
  sector         = 'Technologie / Logiciel',
  size           = 'PME (10-50)',
  updated_at     = NOW()
WHERE id = 1;

-- ============================================================
-- 2. UTILISATEURS
-- ============================================================

-- Renommer Jaeson → Jason
UPDATE users SET
  first_name    = 'Jason',
  email         = 'jason.morant@collabsme.com',
  phone_number  = '+237 699 456 789',
  bio           = 'Lead Développeur Full Stack, expert Flutter et Spring Boot'
WHERE id = 2;

-- Créer Sarah Djoumessi (MEMBER)
INSERT INTO users (bio, date_joined, email, first_name, is_company_admin, last_name, password, phone_number, preferences, role, company_id)
VALUES (
  'Développeuse Full Stack spécialisée en Flutter et Spring Boot',
  NOW(),
  'sarah.djoumessi@collabsme.com',
  'Sarah',
  0,
  'Djoumessi',
  '$2a$10$u0tl8isH3/HEXueAPcz7R..t0PHzlWl69exFXfZNDTjGf0hnXHA1m',
  '+237 699 654 321',
  '{}',
  'MEMBER',
  1
);

-- Créer Paul Ngassa (MEMBER)
INSERT INTO users (bio, date_joined, email, first_name, is_company_admin, last_name, password, phone_number, preferences, role, company_id)
VALUES (
  'Ingénieur DevOps passionné par le cloud et l''automatisation',
  NOW(),
  'paul.ngassa@collabsme.com',
  'Paul',
  0,
  'Ngassa',
  '$2a$10$u0tl8isH3/HEXueAPcz7R..t0PHzlWl69exFXfZNDTjGf0hnXHA1m',
  '+237 699 789 012',
  '{}',
  'MEMBER',
  1
);

-- ============================================================
-- 3. PROJETS EXISTANTS — Enrichir descriptions
-- ============================================================
UPDATE projects SET
  description    = 'Mise en place d''un pipeline CI/CD automatisé avec GitHub Actions pour les déploiements continus',
  tags           = '["ci-cd","github-actions","devops","automatisation"]',
  custom_fields  = '{"budget":600000}',
  updated_at     = NOW()
WHERE id = 11;

UPDATE projects SET
  description    = 'Implémentation d''une stratégie de versioning sémantique avec Git Flow et GitHub Releases',
  tags           = '["git","versioning","devops","collaboration"]',
  custom_fields  = '{"budget":400000}',
  updated_at     = NOW()
WHERE id = 12;

UPDATE projects SET
  description    = 'Pipeline CI/CD complet avec GitHub Actions, tests automatisés, build et déploiement sur Firebase Hosting',
  tags           = '["ci-cd","github-actions","firebase","deploiement"]',
  custom_fields  = '{"budget":800000}',
  updated_at     = NOW()
WHERE id = 16;

-- ============================================================
-- 4. NOUVEAUX PROJETS
-- ============================================================

-- Projet A: Application Mobile CollabSME (ACTIVE)
INSERT INTO projects (company_id, created_by_id, created_at, updated_at, title, description, status, priority, start_date, end_date, tags, custom_fields)
VALUES (
  1, 1, NOW(), NOW(),
  'Application Mobile CollabSME',
  'Développement d''une application mobile Flutter pour la gestion de projets collaboratifs en équipe, avec fonctionnalités temps réel, notifications push et tableau Kanban',
  'ACTIVE', 'HIGH', '2026-05-01', '2026-06-30',
  '["mobile","flutter","app","collaboration","kanban"]',
  '{"budget":2500000}'
);

-- Projet B: Infrastructure Cloud AWS (ACTIVE)
INSERT INTO projects (company_id, created_by_id, created_at, updated_at, title, description, status, priority, start_date, end_date, tags, custom_fields)
VALUES (
  1, 1, NOW(), NOW(),
  'Infrastructure Cloud AWS',
  'Mise en place de l''infrastructure AWS complète : EC2 pour le calcul, RDS PostgreSQL pour la base de données, S3 pour le stockage, IAM pour la sécurité et VPC pour le réseau',
  'ACTIVE', 'HIGH', '2026-05-15', '2026-07-15',
  '["aws","cloud","infrastructure","devops","ec2","rds","s3"]',
  '{"budget":1800000}'
);

-- Projet C: Site Web Vitrine (COMPLETED)
INSERT INTO projects (company_id, created_by_id, created_at, updated_at, title, description, status, priority, start_date, end_date, tags, custom_fields)
VALUES (
  1, 1, NOW(), NOW(),
  'Site Web Vitrine CollabSME',
  'Site corporate vitrine responsive pour présenter les services de CollabSME Solutions, avec portfolio, blog et formulaire de contact',
  'COMPLETED', 'MEDIUM', '2026-03-01', '2026-04-30',
  '["web","vitrine","corporate","html-css","responsive"]',
  '{"budget":950000}'
);

-- Projet D: Refonte Base de Données (DRAFT)
INSERT INTO projects (company_id, created_by_id, created_at, updated_at, title, description, status, priority, tags, custom_fields)
VALUES (
  1, 1, NOW(), NOW(),
  'Refonte Base de Données',
  'Migration et optimisation de la base de données vers une architecture plus performante et scalable, avec passage à PostgreSQL et mise en place de réplication',
  'DRAFT', 'MEDIUM',
  '["base-de-donnees","migration","optimisation","architecture","postgresql"]',
  '{"budget":600000}'
);

-- ============================================================
-- 5. PROJECT MEMBERS
-- ============================================================

-- Projet 11 (Pipeline)
INSERT IGNORE INTO project_members (project_id, user_id, role, joined_at)
VALUES (11, 3, 'MEMBER', NOW()), (11, 4, 'MEMBER', NOW());

-- Projet 12 (Versioning)
INSERT IGNORE INTO project_members (project_id, user_id, role, joined_at)
VALUES (12, 3, 'MEMBER', NOW()), (12, 4, 'MEMBER', NOW());

-- Projet 16 (PIPELINE CI-CD)
INSERT IGNORE INTO project_members (project_id, user_id, role, joined_at)
VALUES (16, 3, 'MEMBER', NOW()), (16, 4, 'MEMBER', NOW());

-- Projet 17 (App Mobile) — Lead: Jason
INSERT INTO project_members (project_id, user_id, role, joined_at)
VALUES (17, 1, 'ADMIN', NOW()), (17, 2, 'LEAD', NOW()),
       (17, 3, 'MEMBER', NOW()), (17, 4, 'MEMBER', NOW());

-- Projet 18 (Infra AWS) — Lead: Yvan (créateur)
INSERT INTO project_members (project_id, user_id, role, joined_at)
VALUES (18, 1, 'ADMIN', NOW()), (18, 2, 'MEMBER', NOW()),
       (18, 3, 'MEMBER', NOW()), (18, 4, 'MEMBER', NOW());

-- Projet 19 (Site Web) — Lead: Jason
INSERT INTO project_members (project_id, user_id, role, joined_at)
VALUES (19, 1, 'ADMIN', NOW()), (19, 2, 'LEAD', NOW()),
       (19, 3, 'MEMBER', NOW()), (19, 4, 'MEMBER', NOW());

-- Projet 20 (Refonte BDD) — Lead: Sarah
INSERT INTO project_members (project_id, user_id, role, joined_at)
VALUES (20, 1, 'ADMIN', NOW()), (20, 3, 'LEAD', NOW()),
       (20, 2, 'MEMBER', NOW()), (20, 4, 'MEMBER', NOW());

-- ============================================================
-- 6. TÂCHES
-- ============================================================

-- Projet 11 (Pipeline, DRAFT) — 2 tâches
INSERT INTO tasks (project_id, created_by_id, assigned_to_id, created_at, updated_at, title, description, status, priority, due_date, item_order, tags, custom_fields, estimated_hours, actual_hours, start_date)
VALUES (11, 1, 2, '2026-05-20 09:00:00', '2026-05-25 14:00:00', 'Configuration GitHub Actions',
        'Créer les workflows CI pour les branches main et develop', 'DONE', 'HIGH', '2026-06-10', 1,
        '["ci-cd","github-actions","workflows"]', '{}', 16, 14, '2026-05-20');

INSERT INTO tasks (project_id, created_by_id, assigned_to_id, created_at, updated_at, title, description, status, priority, due_date, item_order, tags, custom_fields, estimated_hours, actual_hours, start_date)
VALUES (11, 1, 4, '2026-05-25 10:00:00', '2026-05-25 10:00:00', 'Mise en place des tests automatisés',
        'Configurer les tests unitaires et d''intégration dans le pipeline', 'TODO', 'MEDIUM', '2026-05-25', 2,
        '["tests","ci-cd","automatisation"]', '{}', 12, NULL, '2026-05-25');

-- Projet 12 (Versioning, ACTIVE) — 2 tâches
INSERT INTO tasks (project_id, created_by_id, assigned_to_id, created_at, updated_at, title, description, status, priority, due_date, item_order, tags, custom_fields, estimated_hours, actual_hours, start_date)
VALUES (12, 1, 2, '2026-05-22 08:00:00', '2026-05-29 09:00:00', 'Migration vers Git Flow',
        'Migrer le repository actuel vers la convention Git Flow avec branches feature, develop et main', 'IN_PROGRESS', 'HIGH', '2026-06-10', 1,
        '["git","versioning","git-flow"]', '{}', 20, 12, '2026-05-22');

INSERT INTO tasks (project_id, created_by_id, assigned_to_id, created_at, updated_at, title, description, status, priority, due_date, item_order, tags, custom_fields, estimated_hours, actual_hours, start_date)
VALUES (12, 1, 4, '2026-05-25 11:00:00', '2026-05-25 11:00:00', 'Configuration GitHub Releases',
        'Automatiser la création de releases GitHub avec changelog et tags sémantiques', 'TODO', 'MEDIUM', '2026-06-25', 2,
        '["github","releases","automatisation"]', '{}', 8, NULL, '2026-05-25');

-- Projet 16 (PIPELINE CI-CD, COMPLETED) — 3 tâches terminées
INSERT INTO tasks (project_id, created_by_id, assigned_to_id, created_at, updated_at, title, description, status, priority, due_date, item_order, tags, custom_fields, estimated_hours, actual_hours, start_date)
VALUES (16, 1, 1, '2026-05-10 08:00:00', '2026-05-19 16:00:00', 'Création workflow CI',
        'Mettre en place le workflow d''intégration continue avec build, lint et tests', 'DONE', 'HIGH', '2026-05-20', 1,
        '["ci","github-actions","workflows"]', '{}', 24, 22, '2026-05-10');

INSERT INTO tasks (project_id, created_by_id, assigned_to_id, created_at, updated_at, title, description, status, priority, due_date, item_order, tags, custom_fields, estimated_hours, actual_hours, start_date)
VALUES (16, 1, 2, '2026-05-15 09:00:00', '2026-05-24 17:00:00', 'Création workflow CD',
        'Mettre en place le déploiement continu vers Firebase Hosting et staging', 'DONE', 'HIGH', '2026-05-25', 2,
        '["cd","firebase","deploiement"]', '{}', 16, 18, '2026-05-15');

INSERT INTO tasks (project_id, created_by_id, assigned_to_id, created_at, updated_at, title, description, status, priority, due_date, item_order, tags, custom_fields, estimated_hours, actual_hours, start_date)
VALUES (16, 1, 3, '2026-05-20 10:00:00', '2026-05-27 15:00:00', 'Documentation pipeline',
        'Rédiger la documentation technique du pipeline CI/CD pour l''équipe', 'DONE', 'LOW', '2026-05-28', 3,
        '["documentation","ci-cd","technique"]', '{}', 6, 5, '2026-05-20');

-- Projet 17 (App Mobile, ACTIVE) — 5 tâches
INSERT INTO tasks (project_id, created_by_id, assigned_to_id, created_at, updated_at, title, description, status, priority, due_date, item_order, tags, custom_fields, estimated_hours, actual_hours, start_date)
VALUES (17, 2, 3, '2026-05-02 08:00:00', '2026-05-09 17:00:00', 'Design UI/UX Figma',
        'Conception des maquettes complètes de l''application sur Figma : login, dashboard, projets, tâches, profil', 'DONE', 'HIGH', '2026-05-10', 1,
        '["design","ui-ux","figma","maquettes"]', '{}', 40, 38, '2026-05-02');

INSERT INTO tasks (project_id, created_by_id, assigned_to_id, created_at, updated_at, title, description, status, priority, due_date, item_order, tags, custom_fields, estimated_hours, actual_hours, start_date)
VALUES (17, 2, 1, '2026-05-05 09:00:00', '2026-05-29 10:00:00', 'Développement backend API',
        'Développer l''API REST Spring Boot avec JWT, gestion des projets, tâches, membres et notifications', 'IN_PROGRESS', 'HIGH', '2026-06-05', 2,
        '["backend","api","spring-boot","jwt"]', '{}', 80, 55, '2026-05-05');

INSERT INTO tasks (project_id, created_by_id, assigned_to_id, created_at, updated_at, title, description, status, priority, due_date, item_order, tags, custom_fields, estimated_hours, actual_hours, start_date)
VALUES (17, 2, 2, '2026-05-10 10:00:00', '2026-05-29 10:00:00', 'Intégration Flutter',
        'Développer l''application Flutter avec les écrans : login, dashboard, liste projets, détails, board Kanban, profil', 'IN_PROGRESS', 'HIGH', '2026-06-15', 3,
        '["flutter","frontend","mobile","ui"]', '{}', 60, 35, '2026-05-10');

INSERT INTO tasks (project_id, created_by_id, assigned_to_id, created_at, updated_at, title, description, status, priority, due_date, item_order, tags, custom_fields, estimated_hours, actual_hours, start_date)
VALUES (17, 2, 4, '2026-05-20 11:00:00', '2026-05-20 11:00:00', 'Tests utilisateurs',
        'Planifier et exécuter les tests utilisateur avec un groupe de beta-testeurs, remonter les bugs', 'TODO', 'MEDIUM', '2026-05-29', 4,
        '["tests","qa","utilisateurs","recette"]', '{}', 30, NULL, '2026-05-20');

INSERT INTO tasks (project_id, created_by_id, assigned_to_id, created_at, updated_at, title, description, status, priority, due_date, item_order, tags, custom_fields, estimated_hours, actual_hours, start_date)
VALUES (17, 2, 1, '2026-05-25 14:00:00', '2026-05-25 14:00:00', 'Déploiement Play Store',
        'Préparer le build de production, créer le compte développeur et publier l''application sur Google Play Store', 'TODO', 'HIGH', '2026-06-30', 5,
        '["deploiement","play-store","production"]', '{}', 16, NULL, '2026-05-25');

-- Projet 18 (Infra AWS, ACTIVE) — 3 tâches
INSERT INTO tasks (project_id, created_by_id, assigned_to_id, created_at, updated_at, title, description, status, priority, due_date, item_order, tags, custom_fields, estimated_hours, actual_hours, start_date)
VALUES (18, 1, 1, '2026-05-16 08:00:00', '2026-05-19 16:00:00', 'Configuration VPC',
        'Mettre en place le Virtual Private Cloud AWS avec sous-réseaux publics et privés, NAT Gateway et Security Groups', 'DONE', 'HIGH', '2026-05-20', 1,
        '["aws","vpc","reseau","cloud"]', '{}', 24, 20, '2026-05-16');

INSERT INTO tasks (project_id, created_by_id, assigned_to_id, created_at, updated_at, title, description, status, priority, due_date, item_order, tags, custom_fields, estimated_hours, actual_hours, start_date)
VALUES (18, 1, 2, '2026-05-20 09:00:00', '2026-05-29 10:00:00', 'Mise en place RDS',
        'Provisionner une instance RDS PostgreSQL avec réplication multi-AZ, sauvegardes automatisées et monitoring CloudWatch', 'IN_PROGRESS', 'HIGH', '2026-06-05', 2,
        '["aws","rds","postgresql","base-de-donnees"]', '{}', 32, 18, '2026-05-20');

INSERT INTO tasks (project_id, created_by_id, assigned_to_id, created_at, updated_at, title, description, status, priority, due_date, item_order, tags, custom_fields, estimated_hours, actual_hours, start_date)
VALUES (18, 1, 3, '2026-05-25 10:00:00', '2026-05-25 10:00:00', 'Sécurisation IAM',
        'Configurer les politiques IAM, les rôles et les utilisateurs avec le principe du moindre privilège', 'TODO', 'HIGH', '2026-06-20', 3,
        '["aws","iam","securite","cloud"]', '{}', 24, NULL, '2026-05-25');

-- Projet 19 (Site Web, COMPLETED) — 3 tâches terminées
INSERT INTO tasks (project_id, created_by_id, assigned_to_id, created_at, updated_at, title, description, status, priority, due_date, item_order, tags, custom_fields, estimated_hours, actual_hours, start_date)
VALUES (19, 2, 3, '2026-03-02 08:00:00', '2026-03-14 17:00:00', 'Maquettes graphiques',
        'Création des maquettes du site vitrine sur Figma : accueil, services, portfolio, blog, contact', 'DONE', 'MEDIUM', '2026-03-15', 1,
        '["design","maquettes","figma","web"]', '{}', 20, 18, '2026-03-02');

INSERT INTO tasks (project_id, created_by_id, assigned_to_id, created_at, updated_at, title, description, status, priority, due_date, item_order, tags, custom_fields, estimated_hours, actual_hours, start_date)
VALUES (19, 2, 2, '2026-03-16 09:00:00', '2026-04-04 17:00:00', 'Intégration HTML/CSS',
        'Intégration responsive des maquettes en HTML5, CSS3 et JavaScript vanilla avec animations', 'DONE', 'MEDIUM', '2026-04-05', 2,
        '["html","css","integration","responsive"]', '{}', 30, 28, '2026-03-16');

INSERT INTO tasks (project_id, created_by_id, assigned_to_id, created_at, updated_at, title, description, status, priority, due_date, item_order, tags, custom_fields, estimated_hours, actual_hours, start_date)
VALUES (19, 2, 1, '2026-04-06 10:00:00', '2026-04-27 16:00:00', 'Mise en ligne',
        'Configuration du nom de domaine, déploiement sur serveur mutualisé, mise en place SSL et SEO de base', 'DONE', 'HIGH', '2026-04-28', 3,
        '["deploiement","hebergement","ssl","domaine"]', '{}', 12, 10, '2026-04-06');

-- Projet 20 (Refonte BDD, DRAFT) — 2 tâches
INSERT INTO tasks (project_id, created_by_id, assigned_to_id, created_at, updated_at, title, description, status, priority, item_order, tags, custom_fields, estimated_hours, actual_hours)
VALUES (20, 3, 4, NOW(), NOW(), 'Analyse schéma actuel',
        'Auditer le schéma de base de données actuel, identifier les goulots d''étranglement et les axes d''amélioration', 'TODO', 'LOW', 1,
        '["base-de-donnees","audit","analyse","schema"]', '{}', 16, NULL);

INSERT INTO tasks (project_id, created_by_id, assigned_to_id, created_at, updated_at, title, description, status, priority, item_order, tags, custom_fields, estimated_hours, actual_hours)
VALUES (20, 3, 2, NOW(), NOW(), 'Proposition migration',
        'Rédiger une proposition détaillée de migration avec planification, estimation des ressources et analyse des risques', 'TODO', 'LOW', 2,
        '["migration","base-de-donnees","planification"]', '{}', 24, NULL);

-- ============================================================
-- 7. SOUS-TÂCHES (CHECKLIST_ITEMS)
-- ============================================================

-- Tâche "Développement backend API" (id=9) — 3 sous-tâches
INSERT INTO checklist_items (task_id, title, is_completed, item_order)
VALUES
  (9, 'Créer les modèles JPA (User, Project, Task, Comment, Notification)', 1, 1),
  (9, 'Implémenter les endpoints REST (CRUD projets, tâches, utilisateurs)', 1, 2),
  (9, 'Ajouter la sécurité JWT (authentification, refresh tokens, rôles)', 0, 3);

-- Tâche "Intégration Flutter" (id=10) — 3 sous-tâches
INSERT INTO checklist_items (task_id, title, is_completed, item_order)
VALUES
  (10, 'Créer l''écran de connexion et d''inscription avec validation', 1, 1),
  (10, 'Développer le dashboard principal avec graphiques dynamiques', 0, 2),
  (10, 'Connecter les API REST (Provider, repositories, modèles)', 0, 3);

-- Tâche "Mise en place RDS" (id=14) — 2 sous-tâches
INSERT INTO checklist_items (task_id, title, is_completed, item_order)
VALUES
  (14, 'Provisionner l''instance PostgreSQL (db.r6g.large, 100GB SSD)', 1, 1),
  (14, 'Configurer les sauvegardes automatiques (snapshots quotidiens, retention 7 jours)', 0, 2);

-- Tâche "Migration vers Git Flow" (id=3) — 2 sous-tâches
INSERT INTO checklist_items (task_id, title, is_completed, item_order)
VALUES
  (3, 'Restructurer les branches (main ← develop ← feature/*)', 1, 1),
  (3, 'Mettre à jour les règles de protection (PR required, status checks)', 0, 2);

-- ============================================================
-- 8. COMMENTAIRES
-- ============================================================
INSERT INTO comments (task_id, author_id, content, created_at)
VALUES
  (9, 1, 'JWT bien avancé, reste à implémenter les refresh tokens et la rotation automatique', '2026-05-27 14:30:00');

INSERT INTO comments (task_id, author_id, content, created_at)
VALUES
  (9, 2, 'Je peux t''aider sur la partie sécurité si tu veux. J''ai déjà fait du Spring Security avec JWT sur un autre projet.', '2026-05-28 09:15:00');

INSERT INTO comments (task_id, author_id, content, created_at)
VALUES
  (10, 2, 'Le dashboard est presque fini. Il manque encore les graphiques dynamiques avec les vraies données.', '2026-05-26 16:45:00');

INSERT INTO comments (task_id, author_id, content, created_at)
VALUES
  (14, 3, 'Instance PostgreSQL opérationnelle en multi-AZ. Les métriques CloudWatch sont en place.', '2026-05-25 11:00:00');

-- Réponse de Jason au commentaire de Yvan sur la tâche 9
INSERT INTO comments (task_id, author_id, content, created_at, parent_id)
VALUES
  (9, 1, 'Avec plaisir ! Je te partage le repo ce soir, on pourra pair-programmer demain.', '2026-05-28 10:30:00', 1);

-- ============================================================
-- 9. NOTIFICATIONS
-- ============================================================
INSERT INTO notifications (user_id, title, message, notification_type, related_id, is_read, created_at)
VALUES
  (1, 'Nouveau commentaire', 'Jason a commenté sur "Développement backend API" : "Je peux t''aider sur la partie sécurité..."', 'COMMENT_ADDED', '9', 0, '2026-05-28 09:15:00');

INSERT INTO notifications (user_id, title, message, notification_type, related_id, is_read, created_at)
VALUES
  (2, 'Tâche terminée', 'Sarah a terminé la tâche "Configuration VPC" dans le projet Infrastructure Cloud AWS', 'TASK_COMPLETED', '13', 1, '2026-05-19 16:00:00');

INSERT INTO notifications (user_id, title, message, notification_type, related_id, is_read, created_at)
VALUES
  (3, 'Assignation tâche', 'Vous avez été assignée à la tâche "Sécurisation IAM" dans le projet Infrastructure Cloud AWS', 'TASK_ASSIGNED', '15', 0, '2026-05-25 10:00:00');

INSERT INTO notifications (user_id, title, message, notification_type, related_id, is_read, created_at)
VALUES
  (4, 'Nouvelle tâche', 'Yvan a créé une nouvelle tâche "Mise en place des tests automatisés" dans le projet Pipeline', 'TASK_CREATED', '2', 1, '2026-05-25 10:00:00');

INSERT INTO notifications (user_id, title, message, notification_type, related_id, is_read, created_at)
VALUES
  (1, 'Tâche terminée', 'Jason a terminé la tâche "Création workflow CD" dans le projet PIPELINE CI-CD', 'TASK_COMPLETED', '6', 0, '2026-05-24 17:00:00');

INSERT INTO notifications (user_id, title, message, notification_type, related_id, is_read, created_at)
VALUES
  (3, 'Projet assigné', 'Vous avez été nommée Lead du projet "Refonte Base de Données"', 'PROJECT_ASSIGNED', '20', 0, NOW());

-- ============================================================
-- 10. ACTIVITY LOGS
-- ============================================================
INSERT INTO activity_logs (actor_id, company_id, action_type, target_description, metadata, timestamp)
VALUES
  (1, 1, 'PROJECT_CREATED', 'Création du projet "Infrastructure Cloud AWS" avec un budget de 1 800 000 FCFA',
   '{"project_id":"18","project_name":"Infrastructure Cloud AWS","budget":1800000,"status":"ACTIVE"}', '2026-05-29 10:00:00');

INSERT INTO activity_logs (actor_id, company_id, action_type, target_description, metadata, timestamp)
VALUES
  (2, 1, 'TASK_CREATED', 'Ajout de la tâche "Sécurisation IAM" dans le projet Infrastructure Cloud AWS',
   '{"project_id":"18","task_id":"15","task_name":"Sécurisation IAM","assignee":"Sarah Djoumessi"}', '2026-05-29 10:30:00');

INSERT INTO activity_logs (actor_id, company_id, action_type, target_description, metadata, timestamp)
VALUES
  (1, 1, 'TASK_COMPLETED', 'Yvan a terminé la tâche "Création workflow CI" dans le projet PIPELINE CI-CD',
   '{"project_id":"16","task_id":"5","task_name":"Création workflow CI"}', '2026-05-23 16:00:00');

INSERT INTO activity_logs (actor_id, company_id, action_type, target_description, metadata, timestamp)
VALUES
  (2, 1, 'TASK_COMPLETED', 'Jason a terminé la tâche "Création workflow CD" dans le projet PIPELINE CI-CD',
   '{"project_id":"16","task_id":"6","task_name":"Création workflow CD"}', '2026-05-24 17:00:00');

INSERT INTO activity_logs (actor_id, company_id, action_type, target_description, metadata, timestamp)
VALUES
  (1, 1, 'TASK_COMPLETED', 'Yvan a terminé la tâche "Configuration GitHub Actions" dans le projet Pipeline',
   '{"project_id":"11","task_id":"1","task_name":"Configuration GitHub Actions"}', '2026-05-25 14:00:00');

INSERT INTO activity_logs (actor_id, company_id, action_type, target_description, metadata, timestamp)
VALUES
  (3, 1, 'TASK_COMPLETED', 'Sarah a terminé la tâche "Documentation pipeline" dans le projet PIPELINE CI-CD',
   '{"project_id":"16","task_id":"7","task_name":"Documentation pipeline"}', '2026-05-27 15:00:00');

INSERT INTO activity_logs (actor_id, company_id, action_type, target_description, metadata, timestamp)
VALUES
  (1, 1, 'TASK_COMPLETED', 'Yvan a terminé la tâche "Configuration VPC" dans le projet Infrastructure Cloud AWS',
   '{"project_id":"18","task_id":"13","task_name":"Configuration VPC"}', '2026-05-29 11:00:00');

INSERT INTO activity_logs (actor_id, company_id, action_type, target_description, metadata, timestamp)
VALUES
  (1, 1, 'MEMBER_ADDED', 'Ajout de Paul Ngassa au projet "Application Mobile CollabSME" en tant que membre',
   '{"project_id":"17","project_name":"Application Mobile CollabSME","user_id":"4","user_name":"Paul Ngassa","role":"MEMBER"}', '2026-05-29 14:00:00');

INSERT INTO activity_logs (actor_id, company_id, action_type, target_description, metadata, timestamp)
VALUES
  (2, 1, 'COMMENT_ADDED', 'Jason a commenté sur la tâche "Développement backend API" : "Je peux t''aider sur la sécurité"',
   '{"project_id":"17","task_id":"9","task_name":"Développement backend API","comment_id":"2"}', '2026-05-29 09:00:00');

COMMIT;
