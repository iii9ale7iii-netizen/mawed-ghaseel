import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/session_service.dart';
import '../theme/app_glass_ui.dart';

class WashNotificationsScreen extends StatelessWidget {
  const WashNotificationsScreen({super.key});

  Future<void> markAsRead(String notificationId) async {
    final washId = SessionService.currentWashId ?? '';

    if (washId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('notification_reads')
        .doc('${washId}_$notificationId')
        .set({
          'userId': washId,
          'notificationId': notificationId,
          'userType': 'wash',
          'readAt': Timestamp.now(),
        });
  }

  Stream<QuerySnapshot> notificationsStream() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> readStatusStream(String notificationId) {
    final washId = SessionService.currentWashId ?? '';

    return FirebaseFirestore.instance
        .collection('notification_reads')
        .doc('${washId}_$notificationId')
        .snapshots();
  }

  bool canWashSeeNotification(Map<String, dynamic> data) {
    final target = data['target']?.toString() ?? 'all';
    final isActive = data['isActive'] == true;

    return isActive && (target == 'all' || target == 'washes');
  }

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    return '';
  }

  Widget _notificationCard({
    required String notificationId,
    required Map<String, dynamic> data,
    required bool isRead,
  }) {
    final title = data['title']?.toString() ?? '';
    final body = data['body']?.toString() ?? '';
    final createdAt = formatDate(data['createdAt']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppGlassCard(
        padding: const EdgeInsets.all(15),
        color: isRead ? null : const Color(0xFFEAF6FF).withValues(alpha: 0.90),
        child: InkWell(
          onTap: () => markAsRead(notificationId),
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppActionIcon(
                    icon: isRead
                        ? Icons.notifications_none_rounded
                        : Icons.notifications_active_rounded,
                    active: !isRead,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppGlassUi.darkText,
                            fontSize: 16.5,
                            fontWeight: isRead ? FontWeight.w800 : FontWeight.w900,
                            height: 1.35,
                          ),
                        ),
                        if (createdAt.isNotEmpty)
                          AppInfoRow(
                            icon: Icons.date_range_rounded,
                            text: createdAt,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AppStatusChip(
                    label: isRead ? 'مقروء' : 'جديد',
                    color: isRead ? AppGlassUi.mutedText : AppGlassUi.primary,
                  ),
                ],
              ),
              if (body.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppGlassUi.mutedText,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
              ],
              if (!isRead) ...[
                const SizedBox(height: 12),
                AppGradientButton(
                  title: 'تحديد كمقروء',
                  icon: Icons.done_rounded,
                  onTap: () => markAsRead(notificationId),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _notificationsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: notificationsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingState();
        }

        if (snapshot.hasError) {
          return AppEmptyState(
            title: 'حدث خطأ: ${snapshot.error}',
            icon: Icons.error_outline_rounded,
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const AppEmptyState(
            title: 'لا توجد إشعارات حالياً',
            icon: Icons.notifications_none_rounded,
          );
        }

        final notifications = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return canWashSeeNotification(data);
        }).toList();

        if (notifications.isEmpty) {
          return const AppEmptyState(
            title: 'لا توجد إشعارات حالياً',
            icon: Icons.notifications_none_rounded,
          );
        }

        return Column(
          children: notifications.map((notification) {
            final data = notification.data() as Map<String, dynamic>;

            return StreamBuilder<DocumentSnapshot>(
              stream: readStatusStream(notification.id),
              builder: (context, readSnapshot) {
                final isRead = readSnapshot.hasData && readSnapshot.data!.exists;

                return _notificationCard(
                  notificationId: notification.id,
                  data: data,
                  isRead: isRead,
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppGlassScaffold(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppGlassTopBar(
              title: 'إشعارات المغسلة',
              leadingIcon: Icons.arrow_back_rounded,
              leadingTooltip: 'رجوع',
            ),
            const SizedBox(height: 18),
            const AppSectionTitle(
              title: 'الإشعارات',
              subtitle: 'تابع التنبيهات والرسائل الجديدة',
              icon: Icons.notifications_rounded,
            ),
            const SizedBox(height: 12),
            _notificationsList(),
          ],
        ),
      ),
    );
  }
}
