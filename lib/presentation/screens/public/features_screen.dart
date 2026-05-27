import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';

class FeaturesScreen extends StatefulWidget {
  const FeaturesScreen({super.key});

  @override
  State<FeaturesScreen> createState() => _FeaturesScreenState();
}

class _FeaturesScreenState extends State<FeaturesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final _categories = <_FeatureCategory>[
    _FeatureCategory("Kanban", LucideIcons.columns, "Tableau Kanban interactif", [
      _FeatureDetail("Glisser-deposer", "Deplacez les taches entre les colonnes d'un simple geste.", LucideIcons.arrowLeftRight),
      _FeatureDetail("Statuts personnalisables", "A faire, En cours, Revision, Termine — ou creez les votres.", LucideIcons.slidersHorizontal),
      _FeatureDetail("Filtres avances", "Filtrez par statut, priorite, assigne ou date d'echeance.", LucideIcons.listFilter),
      _FeatureDetail("Recherche globale", "Recherche instantanee dans toutes les taches du projet.", LucideIcons.search),
      _FeatureDetail("Vue compacte / detaillee", "Basculez entre vue condensee et vue detaillee.", LucideIcons.layout),
    ]),
    _FeatureCategory("Assistant IA", LucideIcons.sparkles, "Productivite augmentee par l'intelligence artificielle", [
      _FeatureDetail("Chat intelligent", "Posez des questions sur vos projets et obtenez des reponses contextuelles.", LucideIcons.messageSquare),
      _FeatureDetail("Resume automatique", "Generez un resume de projet en un clic.", LucideIcons.fileText),
      _FeatureDetail("Generation de taches", "Creez des taches a partir d'une description en langage naturel.", LucideIcons.wand2),
      _FeatureDetail("Detection de risques", "Identifiez automatiquement les taches en retard ou a risque.", LucideIcons.shieldAlert),
      _FeatureDetail("Suggestion d'assignation", "L'IA suggere le meilleur membre pour chaque tache.", LucideIcons.brainCircuit),
    ]),
    _FeatureCategory("Temps reel", LucideIcons.bell, "Notifications et synchronisation instantanees", [
      _FeatureDetail("WebSocket temps reel", "Mises a jour en direct sans rechargement de page.", LucideIcons.zap),
      _FeatureDetail("Notifications poushees", "Alertes pour les changements, commentaires et assignations.", LucideIcons.bellDot),
      _FeatureDetail("Fallback HTTP", "Repli automatique vers HTTP si WebSocket est indisponible.", LucideIcons.refreshCw),
      _FeatureDetail("Flux d'activite", "Historique en temps reel des actions de l'equipe.", LucideIcons.activity),
      _FeatureDetail("Cache local", "Les donnees restent accessibles meme hors ligne.", LucideIcons.database),
    ]),
    _FeatureCategory("Rapports", LucideIcons.barChart3, "Analyses et exports pour piloter vos projets", [
      _FeatureDetail("Tableau de bord", "Vue d'ensemble des indicateurs cle de votre entreprise.", LucideIcons.layoutDashboard),
      _FeatureDetail("Taux de completion", "Suivez l'avancement global de chaque projet.", LucideIcons.pieChart),
      _FeatureDetail("Export CSV", "Telechargez vos donnees pour les analyser dans Excel.", LucideIcons.fileSpreadsheet),
      _FeatureDetail("Graphiques dynamiques", "Visualisez la repartition des taches par statut.", LucideIcons.trendingUp),
      _FeatureDetail("Rapports personnalises", "Filtrez et personnalisez vos exports.", LucideIcons.settings2),
    ]),
    _FeatureCategory("Calendrier", LucideIcons.calendar, "Visualisation temporelle de vos projets", [
      _FeatureDetail("Vue mensuelle", "Apercu du mois en cours avec les echeances.", LucideIcons.calendarDays),
      _FeatureDetail("Vue par jour", "Liste detaillee des taches au clic sur un jour.", LucideIcons.calendarCheck),
      _FeatureDetail("Navigation intuitive", "Mois suivant / precedent avec animation fluide.", LucideIcons.chevronLeft),
      _FeatureDetail("Code couleur", "Taches colorees par statut et priorite.", LucideIcons.palette),
      _FeatureDetail("Filtrage", "Affichez seulement les taches assignees a vous.", LucideIcons.filter),
    ]),
    _FeatureCategory("Equipe", LucideIcons.users, "Collaboration et gestion des acces", [
      _FeatureDetail("Roles granulaires", "Admin, Lead, Membre — chaque role a ses permissions.", LucideIcons.shield),
      _FeatureDetail("Permissions par projet", "Controle d'acces fin au niveau du projet.", LucideIcons.lock),
      _FeatureDetail("Charge de travail", "Visualisez la repartition des taches par membre.", LucideIcons.ganttChart),
      _FeatureDetail("Invitations par email", "Ajoutez des membres en un clic.", LucideIcons.mailPlus),
      _FeatureDetail("Multi-entreprise", "Chaque societe a ses donnees isolees et securisees.", LucideIcons.building2),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _categories.length, vsync: this, initialIndex: 0);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Fonctionnalites", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: _categories.map((c) => Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(c.icon, size: 16),
                const SizedBox(width: 8),
                Text(c.title),
              ],
            ),
          )).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: _categories.map((cat) => _buildFeaturePage(cat)).toList(),
      ),
    );
  }

  Widget _buildFeaturePage(_FeatureCategory cat) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(cat.icon, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cat.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 28, letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                      Text(cat.subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 48),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: cat.items.map((item) {
                      return SizedBox(
                        width: isWide ? 380 : double.infinity,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.background),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(item.icon, size: 18, color: AppColors.primary),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(item.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCategory {
  final String title;
  final IconData icon;
  final String subtitle;
  final List<_FeatureDetail> items;
  const _FeatureCategory(this.title, this.icon, this.subtitle, this.items);
}

class _FeatureDetail {
  final String title;
  final String description;
  final IconData icon;
  const _FeatureDetail(this.title, this.description, this.icon);
}
