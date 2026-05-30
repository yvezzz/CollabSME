import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/route_helper.dart';
import '../../../utils/safe_parser.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _format = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _tasksByDay = {};
  bool _isLoading = true;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final resp = await ApiClient.get('tasks/my-tasks/');
      if (resp.statusCode == 200) {
        final decoded = SafeParser.safeDecodeList(resp.body);
        if (decoded == null) {
          setState(() => _isLoading = false);
          return;
        }
        final grouped = <DateTime, List<Map<String, dynamic>>>{};
        for (final t in decoded) {
          if (t is! Map) continue;
          final date = SafeParser.parseString(t['due_date']);
          if (date.isEmpty) continue;
          final parsed = DateTime.tryParse(date);
          if (parsed == null) continue;
          final dayKey = DateTime(parsed.year, parsed.month, parsed.day);
          grouped.putIfAbsent(dayKey, () => []).add(Map<String, dynamic>.from(t));
        }
        setState(() => _tasksByDay = grouped);
      }
    } catch (_) {
      // ignore calendar load errors — shows empty state
    }
    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> _getTasksForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    var tasks = _tasksByDay[key] ?? [];
    if (_statusFilter != null) {
      tasks = tasks.where((t) => t['status'] == _statusFilter).toList();
    }
    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          DateFormat('MMMM yyyy', 'fr_FR').format(_focusedDay),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2035),
            focusedDay: _focusedDay,
            calendarFormat: _format,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onFormatChanged: (format) => setState(() => _format = format),
            onPageChanged: (focused) => setState(() => _focusedDay = focused),
            eventLoader: (day) => _getTasksForDay(day),
            locale: 'fr_FR',
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              titleTextStyle: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              formatButtonDecoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              formatButtonTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
              leftChevronIcon: const Icon(LucideIcons.chevronLeft, color: AppColors.primary),
              rightChevronIcon: const Icon(LucideIcons.chevronRight, color: AppColors.primary),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              defaultDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              weekendDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              outsideDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              markerDecoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              defaultTextStyle: const TextStyle(color: Colors.white),
              weekendTextStyle: const TextStyle(color: AppColors.textSecondary),
              outsideTextStyle: const TextStyle(color: AppColors.textSecondary),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
              weekendStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          ),
          const Divider(color: AppColors.card, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip("Toutes", null),
                const SizedBox(width: 8),
                _buildFilterChip("En cours", 'IN_PROGRESS'),
                const SizedBox(width: 8),
                _buildFilterChip("Terminé", 'DONE'),
                const SizedBox(width: 8),
                _buildFilterChip("Révision", 'REVIEW'),
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
    final dateStr = DateFormat('EEEE d MMMM', 'fr_FR').format(_selectedDay!);
    var tasks = _getTasksForDay(_selectedDay!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            dateStr,
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
                    title: Text(t['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(t['project_title']?.toString() ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: _priorityBadge(t['priority']?.toString() ?? ''),
                    onTap: () => Navigator.pushNamed(context, '${Routes.taskDetail}/${t['project']}/${t['id']}'),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _statusFilter == status;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
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
