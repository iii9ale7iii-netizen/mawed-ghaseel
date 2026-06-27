import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_glass_ui.dart';
import '../main.dart';
import 'admin_coupons_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_notifications_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Widget adminMenuButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget screen,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppActionCard(
        title: title,
        subtitle: subtitle,
        icon: icon,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
      ),
    );
  }

  Widget statusBadge(String status) {
    final isApproved = status == 'approved';

    return AppStatusChip(
      label: isApproved ? 'معتمدة' : 'بانتظار الاعتماد',
      color: isApproved ? Colors.green : Colors.orange,
    );
  }

  Future<void> approveWash(BuildContext context, String washId) async {
    await FirebaseFirestore.instance.collection('washes').doc(washId).update({
      'status': 'approved',
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم اعتماد المغسلة')),
    );
  }

  Future<void> deleteWash(BuildContext context, String washId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('حذف المغسلة'),
            content: const Text('هل أنت متأكد من حذف هذه المغسلة؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('تراجع'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    await FirebaseFirestore.instance.collection('washes').doc(washId).delete();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف المغسلة')),
    );
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Widget washesManagementSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('washes').snapshots(),
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
            title: 'لا توجد مغاسل مسجلة حالياً',
            icon: Icons.local_car_wash_outlined,
          );
        }

        final washes = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionTitle(
              title: 'إدارة المغاسل',
              subtitle: 'اعتماد المغاسل الجديدة أو حذف الحسابات غير المناسبة',
              icon: Icons.local_car_wash_rounded,
            ),
            const SizedBox(height: 12),
            ...washes.map((wash) {
              final data = wash.data() as Map<String, dynamic>;
              final status = data['status']?.toString() ?? 'pending';
              final washName =
                  data['washName']?.toString() ??
                  data['name']?.toString() ??
                  'بدون اسم';
              final email = data['email']?.toString() ?? '';
              final city = data['city']?.toString() ?? '';
              final washType = data['washType']?.toString() ?? '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppGlassCard(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const AppActionIcon(icon: Icons.storefront_rounded),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  washName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppGlassUi.darkText,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (email.isNotEmpty)
                                  AppInfoRow(
                                    icon: Icons.email_outlined,
                                    text: email,
                                  ),
                                AppInfoRow(
                                  icon: Icons.location_city_rounded,
                                  text: [
                                    if (city.isNotEmpty) city,
                                    if (washType.isNotEmpty) washType,
                                  ].join(' - '),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(child: statusBadge(status)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: AppGradientButton(
                              title: 'اعتماد',
                              icon: Icons.verified_rounded,
                              onTap: status == 'approved'
                                  ? null
                                  : () => approveWash(context, wash.id),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AppGradientButton(
                              title: 'حذف',
                              icon: Icons.delete_rounded,
                              danger: true,
                              onTap: () => deleteWash(context, wash.id),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
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
              title: 'لوحة الأدمن',
              actions: [
                AppCircleIconButton(
                  icon: Icons.logout_rounded,
                  tooltip: 'تسجيل الخروج',
                  onTap: () => logout(context),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const AppSectionTitle(
              title: 'إدارة التطبيق',
              subtitle: 'تابع الإحصائيات والإعلانات والكوبونات والمغاسل',
              icon: Icons.admin_panel_settings_rounded,
            ),
            const SizedBox(height: 12),
            adminMenuButton(
              context: context,
              title: 'لوحة الإحصائيات',
              subtitle: 'ملخص العملاء والحجوزات والإعلانات والإيرادات',
              icon: Icons.dashboard_rounded,
              screen: const AdminDashboardScreen(),
            ),
            adminMenuButton(
              context: context,
              title: 'الإشعارات والإعلانات',
              subtitle: 'إرسال إشعارات وإدارة الإعلانات الممولة',
              icon: Icons.campaign_rounded,
              screen: const AdminNotificationsScreen(),
            ),
            adminMenuButton(
              context: context,
              title: 'أكواد الخصم',
              subtitle: 'إضافة وتفعيل وتعطيل كوبونات الخصم',
              icon: Icons.discount_rounded,
              screen: const AdminCouponsScreen(),
            ),
            const SizedBox(height: 18),
            washesManagementSection(),
          ],
        ),
      ),
    );
  }
}
