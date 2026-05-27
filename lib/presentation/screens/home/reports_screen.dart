import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_constants.dart';
import '../../../widgets/glass_container.dart';
import '../../../core/network/api_client.dart';

final reportProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ApiClient.get('projects/reports/');
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  }
  throw Exception("Erreur de chargement du rapport");
});

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(reportProvider);
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 900;
    final horizontalPadding = isDesktop ? screenSize.width * 0.15 : 16.0;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.background,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Rapports",
                  style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Vue d'ensemble de votre entreprise.",
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                reportAsync.when(
                  data: (report) => _buildReportContent(context, report, isDesktop),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.alertTriangle, size: 48, color: AppColors.danger),
                        const SizedBox(height: 16),
                        Text("Erreur: $e", style: const TextStyle(color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(reportProvider),
                          icon: const Icon(LucideIcons.refreshCcw, size: 16),
                          label: const Text("Réessayer"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportContent(BuildContext context, Map<String, dynamic> report, bool isDesktop) {
    final totalProjects = report['total_projects'] ?? 0;
    final totalTasks = report['total_tasks'] ?? 0;
    final completionRate = report['completion_rate'] ?? 0.0;
    final overdueTasks = report['overdue_tasks'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary cards
        isDesktop
            ? Row(
                children: [
                  Expanded(child: _buildStatCard("Projets", "$totalProjects", LucideIcons.briefcase, AppColors.primary)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard("Tâches totales", "$totalTasks", LucideIcons.checkCircle, AppColors.accent)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard("Taux complétion", "$completionRate%", LucideIcons.trendingUp, AppColors.warning)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard("En retard", "$overdueTasks", LucideIcons.alertTriangle, AppColors.danger)),
                ],
              )
            : Column(
                children: [
                  _buildStatCard("Projets", "$totalProjects", LucideIcons.briefcase, AppColors.primary),
                  const SizedBox(height: 12),
                  _buildStatCard("Tâches totales", "$totalTasks", LucideIcons.checkCircle, AppColors.accent),
                  const SizedBox(height: 12),
                  _buildStatCard("Taux complétion", "$completionRate%", LucideIcons.trendingUp, AppColors.warning),
                  const SizedBox(height: 12),
                  _buildStatCard("En retard", "$overdueTasks", LucideIcons.alertTriangle, AppColors.danger),
                ],
              ),
        const SizedBox(height: 32),

        // Project status distribution
        _sectionTitle("PROJETS PAR STATUT"),
        const SizedBox(height: 16),
        _buildPieChart(report['projects_by_status'] as Map<String, dynamic>? ?? {}),
        const SizedBox(height: 32),

        // Export buttons
        _sectionTitle("EXPORT"),
        const SizedBox(height: 16),
        GlassContainer(
          child: ListTile(
            leading: const Icon(LucideIcons.fileText, color: AppColors.primary),
            title: const Text("Export CSV", style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text("Télécharger le rapport au format CSV", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            trailing: IconButton(
              icon: const Icon(LucideIcons.download, color: AppColors.primary),
              onPressed: () => _downloadCsv(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, dynamic> statusData) {
    if (statusData.isEmpty) {
      return const Text("Aucune donnée disponible", style: TextStyle(color: AppColors.textSecondary));
    }

    final colors = [AppColors.primary, AppColors.accent, AppColors.warning, AppColors.danger, AppColors.textSecondary];
    int i = 0;
    final sections = statusData.entries.map((e) {
      final c = colors[i % colors.length];
      i++;
      return PieChartSectionData(
        value: (e.value as num).toDouble(),
        color: c,
        title: '${e.key}\n${e.value}',
        titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
        radius: 40,
      );
    }).toList();

    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          height: 220,
          child: Row(
            children: [
              Expanded(
                child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 30)),
              ),
              const SizedBox(width: 24),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: statusData.entries.map((e) {
                  final c = colors[statusData.entries.toList().indexOf(e) % colors.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 8),
                        Text("${e.key}: ${e.value}", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: AppColors.textSecondary,
      ),
    );
  }

  static Future<void> _downloadCsv(BuildContext context) async {
    try {
      final response = await ApiClient.get('projects/reports/?format=csv');
      if (response.statusCode != 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur lors de l'export CSV")),
          );
        }
        return;
      }
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/rapport_societe.csv');
      await file.writeAsString(response.body);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("CSV exporté : ${file.path}"),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : $e")),
        );
      }
    }
  }
}
