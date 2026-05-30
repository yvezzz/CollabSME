import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/route_helper.dart';
import '../../../utils/safe_parser.dart';

class GlobalSearchDelegate extends SearchDelegate {
  final WidgetRef ref;

  GlobalSearchDelegate({required this.ref});

  @override
  String get searchFieldLabel => "Rechercher projets, tâches...";

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(LucideIcons.x), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.arrowLeft),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults();

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults();

  Widget _buildSearchResults() {
    if (query.length < 2) {
      return const Center(
        child: Text("Saisissez au moins 2 caractères", style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _search(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text("Erreur de recherche", style: TextStyle(color: AppColors.textSecondary)));
        }

        final data = snapshot.data!;
        final projects = data['projects'] as List? ?? [];
        final tasks = data['tasks'] as List? ?? [];

        if (projects.isEmpty && tasks.isEmpty) {
          return const Center(child: Text("Aucun résultat", style: TextStyle(color: AppColors.textSecondary)));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (projects.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text("PROJETS", style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
              ...projects.map((p) => ListTile(
                leading: const Icon(LucideIcons.briefcase, color: AppColors.primary),
                title: Text(p['title'] ?? ''),
                subtitle: Text(p['key'] ?? ''),
                  onTap: () {
                  close(context, null);
                  Navigator.of(context).pushNamed('${Routes.projectDetails}/${p['id']}');
                },
              )),
            ],
            if (tasks.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text("TÂCHES", style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
              ...tasks.map((t) => ListTile(
                leading: const Icon(LucideIcons.checkSquare, color: AppColors.accent),
                title: Text(t['title'] ?? ''),
                subtitle: Text("${t['project_title'] ?? ''} • ${t['status'] ?? ''}"),
                onTap: () {
                  close(context, null);
                  Navigator.of(context).pushNamed('${Routes.projectDetails}/${t['project_id']}');
                },
              )),
            ],
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _search(String q) async {
    final response = await ApiClient.get('projects/search/?q=${Uri.encodeComponent(q)}');
    if (response.statusCode == 200) {
      final json = SafeParser.safeDecodeMap(response.body);
      if (json != null) return json;
      throw Exception("Format de réponse invalide");
    }
    throw Exception("Erreur de recherche (${response.statusCode})");
  }
}
