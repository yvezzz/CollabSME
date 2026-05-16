import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/task_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/task_model.dart';
import '../../../widgets/glass_container.dart';
import '../../../presentation/widgets/app_toast.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.projectId,
    required this.taskId,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  final _commentCtrl = TextEditingController();
  final _subtaskCtrl = TextEditingController();
  TaskModel? _task;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    setState(() { _loading = true; _error = null; });
    try {
      final repo = ref.read(taskRepositoryProvider);
      final task = await repo.getTask(widget.projectId, widget.taskId);
      if (mounted) setState(() { _task = task; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _addComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    _commentCtrl.clear();
    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.addComment(widget.projectId, widget.taskId, text);
      await _loadTask();
    } catch (e) {
      if (mounted) AppToast.show(context, message: 'Erreur : $e', type: ToastType.error);
    }
  }

  Future<void> _toggleSubtask(SubTaskModel st) async {
    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.patchSubtaskChecklist(
        widget.projectId, widget.taskId, st.id,
        isCompleted: !st.isCompleted,
      );
      await _loadTask();
    } catch (e) {
      if (mounted) AppToast.show(context, message: 'Erreur : $e', type: ToastType.error);
    }
  }

  Future<void> _addSubtask() async {
    final title = _subtaskCtrl.text.trim();
    if (title.isEmpty) return;
    _subtaskCtrl.clear();
    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.createSubtask(widget.projectId, widget.taskId, title);
      await _loadTask();
    } catch (e) {
      if (mounted) AppToast.show(context, message: 'Erreur : $e', type: ToastType.error);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg', 'xlsx', 'xls'],
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null) return;
      final repo = ref.read(taskRepositoryProvider);
      await repo.uploadAttachment(widget.projectId, widget.taskId, file.path!, file.name);
      await _loadTask();
      if (mounted) AppToast.show(context, message: 'Fichier ajouté', type: ToastType.success);
    } catch (e) {
      if (mounted) AppToast.show(context, message: 'Erreur : $e', type: ToastType.error);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _subtaskCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_task?.publicId ?? 'Détail tâche', style: GoogleFonts.outfit(fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_task != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _priorityBadge(_task!.priority),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: AppColors.danger)));
    final task = _task!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(task),
          const SizedBox(height: 24),
          _buildInfoRow(task),
          const SizedBox(height: 24),
          if (task.description.isNotEmpty) ...[
            _sectionTitle('Description'),
            const SizedBox(height: 8),
            Text(task.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
          ],
          _buildChecklist(task),
          const SizedBox(height: 24),
          _buildComments(task),
          const SizedBox(height: 24),
          _buildAttachments(task),
        ],
      ),
    );
  }

  Widget _buildHeader(TaskModel task) {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _infoChip(LucideIcons.user, task.assignedToName ?? 'Non assigné'),
                const SizedBox(width: 16),
                _infoChip(LucideIcons.clock, task.status.replaceAll('_', ' ')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(TaskModel task) {
    return Row(
      children: [
        if (task.dueDate != null)
          _infoChip(LucideIcons.calendar, 'Échéance: ${_formatDate(task.dueDate!)}'),
        const Spacer(),
        _infoChip(LucideIcons.messageSquare, '${task.commentsCount}'),
        const SizedBox(width: 12),
        _infoChip(LucideIcons.paperclip, '${task.attachmentsCount}'),
        const SizedBox(width: 12),
        _infoChip(LucideIcons.checkSquare, '${task.subTasksCount}'),
      ],
    );
  }

  Widget _buildChecklist(TaskModel task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Checklist (${task.checklistItems.where((s) => s.isCompleted).length}/${task.checklistItems.length})'),
        const SizedBox(height: 8),
        ...task.checklistItems.map((st) => _subtaskTile(st)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _subtaskCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Nouvelle sous-tâche',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _addSubtask(),
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.plus, color: AppColors.primary),
              onPressed: _addSubtask,
            ),
          ],
        ),
      ],
    );
  }

  Widget _subtaskTile(SubTaskModel st) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            height: 28,
            width: 28,
            child: Checkbox(
              value: st.isCompleted,
              onChanged: (_) => _toggleSubtask(st),
              activeColor: AppColors.accent,
              checkColor: Colors.white,
              side: const BorderSide(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              st.title,
              style: TextStyle(
                color: st.isCompleted ? AppColors.textSecondary : Colors.white,
                decoration: st.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComments(TaskModel task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Commentaires (${task.comments.length})'),
        const SizedBox(height: 8),
        ...task.comments.map((c) => _commentTile(c)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Ajouter un commentaire…',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  border: InputBorder.none,
                ),
                maxLines: 3,
                onSubmitted: (_) => _addComment(),
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.send, color: AppColors.primary),
              onPressed: _addComment,
            ),
          ],
        ),
      ],
    );
  }

  Widget _commentTile(CommentModel c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        borderRadius: 12,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 10,
                    backgroundColor: AppColors.primary,
                    child: Icon(LucideIcons.user, size: 10, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(c.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), softWrap: true),
                  ),
                  const SizedBox(width: 8),
                  Text(_formatDate(c.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 8),
              Text(c.content, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              if (c.replies.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...c.replies.map((r) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: Text('↳ ${r.authorName}: ${r.content}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachments(TaskModel task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionTitle('Pièces jointes'),
            const Spacer(),
            IconButton(
              icon: const Icon(LucideIcons.paperclip, color: AppColors.primary, size: 20),
              onPressed: _pickFile,
              tooltip: 'Ajouter un fichier',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (task.attachmentsCount == 0)
          Text('Aucune pièce jointe', style: const TextStyle(color: AppColors.textSecondary))
        else
          Text('${task.attachmentsCount} fichier(s)', style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _priorityBadge(String priority) {
    Color color = priority == 'URGENT' || priority == 'HIGH'
        ? AppColors.danger
        : (priority == 'MEDIUM' ? AppColors.warning : AppColors.accent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
