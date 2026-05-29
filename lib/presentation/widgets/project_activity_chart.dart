import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/glass_container.dart';

class ProjectActivityChart extends StatefulWidget {
  const ProjectActivityChart({super.key});

  @override
  State<ProjectActivityChart> createState() => _ProjectActivityChartState();
}

class _ProjectActivityChartState extends State<ProjectActivityChart> {
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final resp = await ApiClient.get('tasks/activity/');
      if (!mounted) return;
      if (resp.statusCode != 200) {
        setState(() => _isLoading = false);
        return;
      }
      final List entries = jsonDecode(resp.body);
      final now = DateTime.now();
      final days = List.generate(7, (i) => DateFormat('d/M').format(now.subtract(Duration(days: 6 - i))));
      final dateStrs = List.generate(7, (i) => DateFormat('yyyy-MM-dd').format(now.subtract(Duration(days: 6 - i))));
      final counts = <int>[0, 0, 0, 0, 0, 0, 0];
      for (final e in entries) {
        final type = e['action_type'] as String?;
        final desc = e['target_description'] as String? ?? '';
        final ts = e['timestamp'] as String?;
        if (ts == null) continue;
        if (type == 'TASK_COMPLETED') { /* ok */ }
        else if (type == 'TASK_UPDATED' && (desc.contains(': DONE') || desc.contains('à DONE') || desc.contains(':COMPLETED'))) { /* ok */ }
        else continue;
        final day = ts.substring(0, 10);
        final idx = dateStrs.indexOf(day);
        if (idx >= 0) counts[idx]++;
      }
      final data = <Map<String, dynamic>>[];
      for (int i = 0; i < 7; i++) {
        data.add({'day': days[i], 'count': counts[i]});
      }
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Activité des Projets",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Tâches complétées (7 derniers jours)",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (!_isLoading && _data.isNotEmpty)
                 Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Total: ${_data.fold<int>(0, (sum, item) => sum + ((item['count'] ?? 0) as int))}",
                    style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _data.isEmpty 
                ? const Center(child: Text("Aucune donnée disponible", style: TextStyle(color: Colors.white38)))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.white.withValues(alpha: 0.05),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value >= 0 && value < _data.length) {
                                final day = _data[value.toInt()]['day']?.toString() ?? '';
                                return Text(
                                  day,
                                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(color: Colors.white38, fontSize: 10),
                              );
                            },
                            reservedSize: 30,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (_data.length - 1).toDouble(),
                      minY: 0,
                      maxY: _getMaxY(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _getSpots(),
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _getMaxY() {
    if (_data.isEmpty) return 10;
    int max = 0;
    for (var item in _data) {
      final count = item['count'];
      if (count != null && count > max) max = count;
    }
    return (max + 2).toDouble();
  }

  List<FlSpot> _getSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < _data.length; i++) {
      final count = _data[i]['count'] ?? 0;
      spots.add(FlSpot(i.toDouble(), (count as int).toDouble()));
    }
    return spots;
  }
}
