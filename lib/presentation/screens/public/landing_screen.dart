import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/route_helper.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scrollCtrl = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() => setState(() => _scrollOffset = _scrollCtrl.offset));
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isScrolled = _scrollOffset > 60;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          _buildAppBar(isScrolled),
          SliverToBoxAdapter(child: _buildHero()),
          SliverToBoxAdapter(child: _buildFeaturesPreview()),
          SliverToBoxAdapter(child: _buildTestimonials()),
          SliverToBoxAdapter(child: _buildStatsSection()),
          SliverToBoxAdapter(child: _buildCTASection()),
          SliverToBoxAdapter(child: _buildFooter()),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool scrolled) {
    return SliverAppBar(
      backgroundColor: scrolled ? AppColors.surface : Colors.transparent,
      elevation: scrolled ? 1 : 0,
      surfaceTintColor: scrolled ? AppColors.surface : Colors.transparent,
      pinned: true,
      expandedHeight: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          border: scrolled ? const Border(bottom: BorderSide(color: AppColors.card, width: 0.5)) : null,
        ),
      ),
      title: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return Row(
            children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Icon(LucideIcons.layout, color: Colors.white, size: 16)),
                ),
              const SizedBox(width: 10),
              Text("CollabSME", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
              if (isWide) ...[
                const Spacer(),
                _navButton("Fonctionnalités", () => Navigator.pushNamed(context, Routes.features)),
                _navButton("Avis", () => Navigator.pushNamed(context, Routes.contact)),
                _navButton("Contact", () => Navigator.pushNamed(context, Routes.contact)),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pushNamed(context, Routes.login),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Connexion", style: TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, Routes.register),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("S'inscrire", style: TextStyle(fontSize: 14)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _navButton(String text, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
        child: Text(text, style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent),
                ),
                const SizedBox(width: 8),
                const Text("Gestion de projet intelligente pour PME",
                  style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Text(
            "Planifiez, collaborez\net livrez plus vite.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -2,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "L'outil de gestion de projet tout-en-un conçu pour les PME.\nKanban, IA, temps reel, rapports — tout dans une interface moderne.",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 17,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, Routes.register),
                icon: const Icon(LucideIcons.rocket, size: 18),
                label: const Text("Commencer gratuitement"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, Routes.features),
                icon: const Icon(LucideIcons.chevronRight, size: 18),
                label: const Text("Decouvrir"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.card, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 64),
          _buildMockup(),
        ],
      ),
    );
  }

  Widget _buildMockup() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.clamp(300, 900).toDouble();
        return Container(
          width: w,
          height: w * 0.6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.card, width: 1),
            color: AppColors.surface,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: 20, left: 20, right: 20,
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                          Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text("Mon Projet", style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                        const Spacer(),
                        ...List.generate(3, (i) => Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.card),
                              color: AppColors.surface,
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 68, left: 20, bottom: 20,
                  child: Container(
                    width: 140,
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _mockupLine(0.8),
                        const SizedBox(height: 4),
                        _mockupLine(0.5),
                        const SizedBox(height: 8),
                        _mockupLine(0.9),
                        _mockupLine(0.4),
                        const SizedBox(height: 8),
                        _mockupLine(0.7),
                        _mockupLine(0.6),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 68, left: 175, right: 20, bottom: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _mockupBadge("A faire", AppColors.warning),
                            const SizedBox(width: 6),
                            _mockupBadge("En cours", AppColors.primary),
                            const SizedBox(width: 6),
                            _mockupBadge("Termine", AppColors.accent),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Row(
                            children: List.generate(3, (col) => Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.background.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.all(6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List.generate(2 + col, (i) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Container(
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: AppColors.card.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  )),
                                ),
                              ),
                            )),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.layout, size: 12, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text("Apercu de l'interface", style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mockupLine(double width) {
    return Container(
      height: 8,
      width: (width * 120).clamp(30, 120),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _mockupBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildFeaturesPreview() {
    final features = [
      (LucideIcons.columns, "Kanban", "Organisez vos taches par colonnes avec un glisser-deposer intuitif."),
      (LucideIcons.sparkles, "Assistant IA", "Un assistant intelligent pour resumer, generer et analyser vos projets."),
      (LucideIcons.bell, "Temps reel", "Notifications et mises a jour instantanees via WebSocket."),
      (LucideIcons.calendar, "Calendrier", "Visualisez toutes vos echeances sur un calendrier interactif."),
      (LucideIcons.barChart3, "Rapports", "Statistiques detaillees et export CSV de vos projets."),
      (LucideIcons.users, "Multi-equipe", "Gerer les roles et permissions par projet avec une granularite totale."),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      color: AppColors.surface,
      child: Column(
        children: [
          Text("FONCTIONNALITES", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.primary)),
          const SizedBox(height: 8),
          Text("Tout ce dont vous avez besoin", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          const Text("Une solution complete pour gerer vos projets de A a Z.", style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: features.map((f) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 400 + features.indexOf(f) * 80),
                    builder: (context, value, child) {
                      return Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child));
                    },
                    child: SizedBox(
                      width: isWide ? 300 : double.infinity,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.background),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(f.$1, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(height: 16),
                            Text(f.$2, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17)),
                            const SizedBox(height: 8),
                            Text(f.$3, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 40),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, Routes.features),
            child: const Text("Voir toutes les fonctionnalites  ->",
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonials() {
    final testimonials = [
      ("Sophie Martin", "CEO, TechStart", "CollabSME a transforme notre facon de travailler. Le Kanban et les rapports nous font gagner un temps fou."),
      ("Lucas Bernard", "Chef de projet, BuildCorp", "L'assistant IA est incroyable. Il nous aide a prioriser et a detecter les risques avant qu'ils ne deviennent critiques."),
      ("Emma Dubois", "Product Owner, WebStudio", "L'interface est superbe et intuitive. Mes equipes ont adopte l'outil en une semaine."),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        children: [
          Text("TEMOIGNAGES", style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.primary)),
          const SizedBox(height: 8),
          Text("Ils nous font confiance", style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
          const SizedBox(height: 48),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: testimonials.map((t) {
                  return SizedBox(
                    width: isWide ? 340 : double.infinity,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.card),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(5, (i) => const Padding(
                              padding: EdgeInsets.only(right: 2),
                              child: Icon(LucideIcons.star, color: AppColors.warning, size: 14),
                            )),
                          ),
                          const SizedBox(height: 16),
                          Text("\"${t.$3}\"", style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    t.$1.split(' ').map((e) => e[0]).take(2).join(),
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(t.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  Text(t.$2, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ],
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
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.card),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 500;
          if (isWide) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _statCard("50+", "Utilisateurs actifs"),
                _divider(),
                _statCard("200+", "Taches creees"),
                _divider(),
                _statCard("99.9%", "Disponibilite"),
              ],
            );
          }
          return Column(
            children: [
              _statCard("50+", "Utilisateurs actifs"),
              _divider(),
              _statCard("200+", "Taches creees"),
              _divider(),
              _statCard("99.9%", "Disponibilite"),
            ],
          );
        },
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 50, color: AppColors.card);
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: -1)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCTASection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        children: [
          Text("Pret a transformer votre gestion de projet ?",
            style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
          const SizedBox(height: 12),
          const Text("Rejoignez des milliers de PME qui nous font confiance.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, Routes.register),
            icon: const Icon(LucideIcons.rocket, size: 18),
            label: const Text("Creer mon compte gratuit"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                          child: const Center(child: Icon(LucideIcons.layout, color: Colors.white, size: 14)),
                        ),
                      const SizedBox(width: 8),
                      Text("CollabSME", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text("Pour les PME qui veulent aller plus loin.",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Produit", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                  const SizedBox(height: 8),
                  _footerLink("Fonctionnalites"),
                  const SizedBox(height: 4),
                  _footerLink("A propos"),
                ],
              ),
              const SizedBox(width: 40),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Legal", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                  const SizedBox(height: 8),
                  _footerLink("Mentions legales"),
                  const SizedBox(height: 4),
                  _footerLink("Confidentialite"),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Divider(color: AppColors.card, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text("2026 CollabSME. Tous droits reserves.",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const Spacer(),
              Row(
                children: [
                  _socialIcon(LucideIcons.twitter),
                  const SizedBox(width: 12),
                  _socialIcon(LucideIcons.github),
                  const SizedBox(width: 12),
                  _socialIcon(LucideIcons.linkedin),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String text) {
    return Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12));
  }

  Widget _socialIcon(IconData icon) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 14, color: AppColors.textSecondary),
    );
  }
}
