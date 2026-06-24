import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/session_service.dart';

class CustomerNotificationsScreen extends StatelessWidget {
  const CustomerNotificationsScreen({super.key});

  Future<void> markAsRead(String notificationId) async {
    final customerId = SessionService.currentCustomerId ?? '';

    if (customerId.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('notification_reads')
        .doc('${customerId}_$notificationId')
        .set({
          'userId': customerId,
          'notificationId': notificationId,
          'userType': 'customer',
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
    final customerId = SessionService.currentCustomerId ?? '';

    return FirebaseFirestore.instance
        .collection('notification_reads')
        .doc('${customerId}_$notificationId')
        .snapshots();
  }

  bool canCustomerSeeNotification(Map<String, dynamic> data) {
    final target = data['target']?.toString() ?? 'all';
    final isActive = data['isActive'] == true;

    return isActive && (target == 'all' || target == 'customers');
  }

  String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإشعارات'), centerTitle: true),
        body: StreamBuilder<QuerySnapshot>(
          stream: notificationsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('لا توجد إشعارات حالياً'));
            }

            final notifications = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return canCustomerSeeNotification(data);
            }).toList();

            if (notifications.isEmpty) {
              return const Center(child: Text('لا توجد إشعارات حالياً'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final data = notification.data() as Map<String, dynamic>;

                return StreamBuilder<DocumentSnapshot>(
                  stream: readStatusStream(notification.id),
                  builder: (context, readSnapshot) {
                    final isRead =
                        readSnapshot.hasData && readSnapshot.data!.exists;

                    return Card(
                      color: isRead ? null : Colors.blue.shade50,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          isRead
                              ? Icons.notifications_none
                              : Icons.notifications_active,
                          color: isRead ? Colors.grey : Colors.blue,
                        ),
                        title: Text(
                          data['title'] ?? '',
                          style: TextStyle(
                            fontWeight: isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${data['body'] ?? ''}\n${formatDate(data['createdAt'])}',
                        ),
                        isThreeLine: true,
                        trailing: isRead
                            ? const Text('مقروء')
                            : TextButton(
                                onPressed: () {
                                  markAsRead(notification.id);
                                },
                                child: const Text('تحديد كمقروء'),
                              ),
                        onTap: () {
                          markAsRead(notification.id);
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
