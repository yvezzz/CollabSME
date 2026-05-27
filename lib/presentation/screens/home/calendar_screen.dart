import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/route_helper.dart';
import '../../screens/tasks/task_detail_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _currentMonth;
  DateTime? _selectedDay;
  Map<String, List<Map<String, dynamic>>> _tasksByDate = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    _selectedDay = DateTime.now();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final resp = await ApiClient.get('tasks/my-tasks/');
      if (resp.statusCode == 200) {
        final List tasks = jsonDecode(resp.body);
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final t in tasks) {
          final date = t['due_date'] as String?;
          if (date != null) {
            final key = date.substring(0, 10);
            grouped.putIfAbsent(key, () => []).add(Map<String, dynamic>.from(t));
          }
        }
        setState(() => _tasksByDate = grouped);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _loadTasks();
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          DateFormat('MMMM yyyy', 'fr_FR').format(_currentMonth),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(LucideIcons.chevronLeft), onPressed: _previousMonth),
          IconButton(icon: const Icon(LucideIcons.chevronRight), onPressed: _nextMonth),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam']
                      .map((d) => Expanded(
                            child: Center(
                              child: Text(d, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                  ),
                  itemCount: firstWeekday + daysInMonth,
                  itemBuilder: (_, index) {
                    if (index < firstWeekday) return const SizedBox();
                    final day = index - firstWeekday + 1;
                    final dateStr = '${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                    final hasTasks = _tasksByDate.containsKey(dateStr);
                    final isToday = dateStr == DateFormat('yyyy-MM-dd').format(DateTime.now());
                    final isSelected = dateStr == (_selectedDay != null ? DateFormat('yyyy-MM-dd').format(_selectedDay!) : null);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDay = DateTime(_currentMonth.year, _currentMonth.month, day)),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : null,
                          borderRadius: BorderRadius.circular(8),
                          border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$day',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isToday ? AppColors.primary : Colors.white,
                              ),
                            ),
                            if (hasTasks)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.card, height: 1),
          Expanded(
            child: _buildDayTasks(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTasks() {
    if (_selectedDay == null) return const SizedBox();
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final tasks = _tasksByDate[dateStr] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            DateFormat('EEEE d MMMM', 'fr_FR').format(_selectedDay!),
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (tasks.isEmpty)
          const Expanded(
            child: Center(
              child: Text("Aucune tâche ce jour", style: TextStyle(color: AppColors.textSecondary)),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: tasks.length,
              itemBuilder: (_, i) {
                final t = tasks[i];
                return Card(
                  color: AppColors.card,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: _statusIcon(t['status'] ?? ''),
                    title: Text(t['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(t['project_title'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: _priorityBadge(t['priority'] ?? ''),
                    onTap: () => Navigator.pushNamed(context, '${Routes.taskDetail}/${t['project']}/${t['id']}'),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _statusIcon(String status) {
    IconData icon;
    Color color;
    switch (status) {
      case 'DONE':
        icon = LucideIcons.checkCircle;
        color = AppColors.accent;
        break;
      case 'IN_PROGRESS':
        icon = LucideIcons.play;
        color = AppColors.primary;
        break;
      case 'REVIEW':
        icon = LucideIcons.eye;
        color = AppColors.warning;
        break;
      default:
        icon = LucideIcons.circle;
        color = AppColors.textSecondary;
    }
    return Icon(icon, color: color, size: 20);
  }

  Widget _priorityBadge(String priority) {
    Color color;
    switch (priority) {
      case 'CRITICAL':
        color = AppColors.danger;
        break;
      case 'HIGH':
        color = Colors.orange;
        break;
      case 'LOW':
        color = AppColors.textSecondary;
        break;
      default:
        color = AppColors.accent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(priority, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }
}
