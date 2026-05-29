import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/route_helper.dart';
import '../../../widgets/glass_container.dart';
import '../../providers/notification_provider.dart';
import '../../../data/models/notification_model.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  void _navigateToRelated(BuildContext context, NotificationModel notif) {
    final relatedId = notif.relatedId;
    if (relatedId == null || relatedId.isEmpty) return;

    switch (notif.type) {
      case 'TASK_ASSIGNED':
      case 'STATUS_CHANGED':
      case 'COMMENT_ADDED':
        Navigator.of(context).pushNamed('${Routes.projectDetails}/$relatedId');
        break;
      default:
        debugPrint("No navigation for notification type: ${notif.type}");
    }
  }

  bool _isLoadingMarkAll = false;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationListProvider);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(ref),
          const SizedBox(height: 32),
          Expanded(
            child: notificationsAsync.when(
              data: (notifications) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(notificationListProvider);
                },
                child: notifications.isEmpty
                    ? ListView(children: [_buildEmptyState()])
                    : ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, index) => _buildNotificationItem(
                          index,
                          notifications[index],
                          ref,
                        ),
                      ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Erreur: $e", style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(notificationListProvider),
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final markAllBtn = _isLoadingMarkAll
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textSecondary,
                ),
              )
            : TextButton.icon(
                onPressed: () => _handleMarkAllRead(ref),
                icon: const Icon(LucideIcons.checkCheck, size: 16),
                label: const Text(
                  "Tout marquer comme lu",
                  style: TextStyle(fontSize: 13),
                ),
              );

        if (constraints.maxWidth < 500) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Notifications",
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                softWrap: true,
              ),
              const SizedBox(height: 4),
              const Text(
                "Restez informé des dernières activités.",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                softWrap: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    onPressed: () => ref.invalidate(notificationListProvider),
                    icon: const Icon(LucideIcons.refreshCcw, size: 20),
                    tooltip: "Rafraîchir",
                  ),
                  markAllBtn,
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Notifications",
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    softWrap: true,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Restez informé des dernières activités.",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    softWrap: true,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => ref.invalidate(notificationListProvider),
              icon: const Icon(LucideIcons.refreshCcw, size: 20),
              tooltip: "Rafraîchir",
            ),
            markAllBtn,
          ],
        );
      },
    );
  }

  Future<void> _handleMarkAllRead(WidgetRef ref) async {
    setState(() => _isLoadingMarkAll = true);
    try {
      await ref.read(notificationListProvider.notifier).markAllAsRead();
    } catch (_) {}
    if (mounted) setState(() => _isLoadingMarkAll = false);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.bellOff,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          const Text(
            "Aucune notification pour le moment",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    int index,
    NotificationModel notification,
    WidgetRef ref,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          ref.read(notificationListProvider.notifier).markAsRead(notification.id);
          _navigateToRelated(context, notification);
        },
        borderRadius: BorderRadius.circular(16),
        child: GlassContainer(
          borderRadius: 16,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIcon(notification.type, notification.isRead),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                fontSize: 16,
                              ),
                              softWrap: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('HH:mm').format(notification.createdAt),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          color: notification.isRead
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildIcon(String type, bool isRead) {
    IconData icon;
    Color color;

    switch (type) {
      case 'TASK_ASSIGNED':
        icon = LucideIcons.checkCircle;
        color = AppColors.primary;
        break;
      case 'STATUS_CHANGED':
        icon = LucideIcons.refreshCw;
        color = Colors.blue;
        break;
      case 'COMMENT_ADDED':
        icon = LucideIcons.messageSquare;
        color = Colors.amber;
        break;
      case 'PROJECT_INVITATION':
        icon = LucideIcons.userPlus;
        color = Colors.orange;
        break;
      case 'SYSTEM':
        icon = LucideIcons.info;
        color = AppColors.accent;
        break;
      default:
        icon = LucideIcons.bell;
        color = AppColors.accent;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (isRead ? Colors.grey : color).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: isRead ? Colors.grey : color),
    );
  }
}
