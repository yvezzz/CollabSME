# CollabSME Frontend - Plateforme de Gestion de Projets Intuitive & Copilote IA

Bienvenue dans le répertoire Frontend de **CollabSME**. Ce projet est une application client riche développée avec **Flutter**, offrant une interface moderne, performante, et résolument tournée vers l'expérience utilisateur avec l'intégration d'une IA Copilote avancée.

CollabSME n'est pas qu'un outil de productivité visuel : c'est un écosystème conçu pour communiquer en temps réel avec le robuste backend Spring Boot.

---

## 🎨 1. Interfaces & Design System

Le design de CollabSME se caractérise par des principes de UI/UX premium :
- **Glassmorphism & Floutage** : Utilisation d'arrière-plans semi-transparents avec des filtres `BackdropFilter` pour un rendu organique et élégant.
- **Micro-Animations Responsives** : Chaque élément interactif (boutons, listes, survol) intègre des animations fluides via `flutter_animate`.
- **Typographie Moderne** : L'interface repose sur la police *Outfit* et *Google Fonts* pour garantir une densité de lecture optimale et une esthétique aérée.
- **Design System Dédié** : Les couleurs principales, secondaires, d'avertissement et de texte sont centralisées dans `AppColors` garantissant la cohérence absolue des composants.

---

## 🏗️ 2. Architecture du Projet (Clean Architecture)

Le projet observe une structure claire basée sur la modularité :

```text
lib/
├── core/                  # Configurations globales (Thèmes, Couleurs, Constantes)
│   └── constants/         # (ex: app_constants.dart)
├── data/                  # Modèles de données (Alignés sur l'API Spring Boot) et Dépôts
│   ├── models/            # Company, User, Project, Task, IA Models, etc.
│   └── repositories/      # Logique de connexion et requêtes API (REST)
├── presentation/          # Vues et State Management (Riverpod)
│   ├── providers/         # Les contrôleurs/states gérant les données de l'interface
│   └── screens/           # Écrans organisés par domaines (Auth, Home, Project)
├── widgets/               # Composants réutilisables (GlassContainer, Boutons, etc.)
└── main.dart              # Point d'entrée de l'application Flutter
```

Cette structuration permet d'isoler la "logique métier" (comment les données sont récupérées et stockées) et "l'interface graphique" (comment les données sont affichées) pour garder un code propre et facilement maintenable.

---

## 🧩 3. Les Modèles de Données & Couche IA (Data Layer)

L'application intègre strictement les modèles de données exposés par le **Backend Koda**, y compris les entités d'Intelligence Artificielle prédictive :

- **Noyau Métier** : Modèles standards pour les Utilisateurs (`UserModel`), les Entreprises (`CompanyModel`), les Projets (`ProjectModel`), et les Tâches (`TaskModel`).
- **Noyau Copilote IA** (`ai_models.dart`) : 
  - `AIPredictionModel` (Gestion algorithmique des retards et risques)
  - `AIBlockageDetectionModel` (Alerte sur les blocages techniques)
  - `AISentimentAnalysisModel` (Outil de santé mentale proactive du projet)
  - Et autres journaux d'historique (RAG, logs).

Toutes ces classes sont prêtes à l'emploi et incluent la conversion `fromJson` et `toJson`.

---

## 🚀 4. Lancement & Développement Local

Koda est pensé pour un développement rapide. Étant donné que le projet est conçu avec Flutter, vous pouvez le lancer à la fois pour le Web, Desktop ou Mobile (iOS/Android).

### Prérequis
- Flutter SDK (3.10+) installé
- Un éditeur de code (VS Code, Android Studio, etc.)
- Le backend Spring Boot (localhost API) doit être en cours d'exécution.

### Lancer le projet
1. Connectez-vous ou ouvrez un terminal dans le répertoire racine :
   ```bash
   cd C:\Users\user\StudioProjects\koda
   ```
2. Mettez à jour les dépendances (Riverpod, Google Fonts, Animations...) :
   ```bash
   flutter pub get
   ```
3. Démarrez l'application web ou l'application locale :
   ```bash
   flutter run -d chrome
   ```
4. Par mesure de bonne pratique, vous pouvez régulièrement inspecter la qualité du code avec :
   ```bash
   dart analyze
   ```

*(Lors de la connexion à l'API en local via l'émulateur Android vers le backend Spring Boot, assurez-vous de lier les URL à `http://10.0.2.2:8000/api/` au lieu de `127.0.0.1`)*.

---

## 🎯 5. Stack Technique et Librairies Clés

Le fichier `pubspec.yaml` intègre des librairies méticuleusement choisies pour un développement Premium :
- **État et Injections :** `flutter_riverpod` (v2.5+)
- **Esthétisation :** `google_fonts`, `lucide_icons`, `font_awesome_flutter`
- **Animations fluides :** `flutter_animate`, `animations`
- **Manipulation des dates :** `intl`

> Si vous connectez la logique authentification réelle par JWT (actuellement prévue en mockup dans la couche Repository), **flutter_secure_storage** est recommandé pour mémoriser les tokens JWT en toute sécurité.

---

**Bon développement sur Koda Frontend !** ✨ L'IA au centre du Design System est le cœur battant de la plateforme. N'hésitez pas à lancer le backend côté serveur pour profiter de toute l'expérience multi-tenant immersive.
