import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_dashboard_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_coupons_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Widget adminMenuButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget screen,
    Color color = Colors.blue,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isApproved ? 'معتمد' : 'بانتظار الاعتماد',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Future<void> approveWash(BuildContext context, String washId) async {
    await FirebaseFirestore.instance.collection('washes').doc(washId).update({
      'status': 'approved',
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم اعتماد المغسلة')));
  }

  Future<void> deleteWash(BuildContext context, String washId) async {
    await FirebaseFirestore.instance.collection('washes').doc(washId).delete();

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم حذف المغسلة')));
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  Widget washesManagementSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('washes').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final washes = snapshot.data!.docs;

        if (washes.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('لا توجد مغاسل مسجلة حالياً'),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إدارة المغاسل',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...washes.map((wash) {
              final data = wash.data() as Map<String, dynamic>;
              final status = data['status']?.toString() ?? 'pending';
              final washName =
                  data['washName']?.toString() ??
                  data['name']?.toString() ??
                  'بدون اسم';
              final email = data['email']?.toString() ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.local_car_wash),
                        title: Text(
                          washName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(email),
                        trailing: statusBadge(status),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: status == 'approved'
                                  ? null
                                  : () => approveWash(context, wash.id),
                              icon: const Icon(Icons.check),
                              label: const Text('اعتماد'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () => deleteWash(context, wash.id),
                              icon: const Icon(Icons.delete),
                              label: const Text('حذف'),
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة الأدمن'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => logout(context),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            adminMenuButton(
              context: context,
              title: 'لوحة الإحصائيات',
              subtitle: 'إحصائيات العملاء والحجوزات والإعلانات والإيرادات',
              icon: Icons.dashboard,
              screen: const AdminDashboardScreen(),
              color: Colors.indigo,
            ),
            adminMenuButton(
              context: context,
              title: 'إدارة الإعلانات',
              subtitle: 'إضافة وتفعيل وتعطيل الإعلانات الممولة',
              icon: Icons.campaign,
              screen: const AdminNotificationsScreen(),
              color: Colors.orange,
            ),
            adminMenuButton(
              context: context,
              title: 'إدارة أكواد الخصم',
              subtitle: 'إضافة وتفعيل وتعطيل أكواد الخصم',
              icon: Icons.discount,
              screen: const AdminCouponsScreen(),
              color: Colors.green,
            ),

            const Divider(height: 30),

            washesManagementSection(),
          ],
        ),
      ),
    );
  }
}
