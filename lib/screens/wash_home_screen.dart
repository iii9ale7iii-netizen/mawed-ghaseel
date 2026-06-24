import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../main.dart';
import '../services/session_service.dart';
import 'service_management_screen.dart';
import 'wash_notifications_screen.dart';

class WashHomeScreen extends StatefulWidget {
  const WashHomeScreen({super.key});

  @override
  State<WashHomeScreen> createState() => _WashHomeScreenState();
}

class _WashHomeScreenState extends State<WashHomeScreen> {
  Future<void> createCustomerNotification({
    required String customerId,
    required String title,
    required String body,
    required String bookingId,
  }) async {
    if (customerId.isEmpty) return;

    await FirebaseFirestore.instance.collection('notifications').add({
      'title': title,
      'body': body,
      'target': 'specific_customer',
      'customerId': customerId,
      'bookingId': bookingId,
      'isActive': true,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> updateStatus(
    String bookingId,
    String status,
    Map<String, dynamic> bookingData,
  ) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({'status': status});

    final customerId = bookingData['customerId']?.toString() ?? '';
    final washName = SessionService.currentWashName ?? 'المغسلة';
    final serviceName = bookingData['serviceName']?.toString() ?? '';
    final date = bookingData['date']?.toString() ?? '';
    final time = bookingData['time']?.toString() ?? '';

    if (status == 'مقبول') {
      await createCustomerNotification(
        customerId: customerId,
        bookingId: bookingId,
        title: 'تم قبول حجزك',
        body:
            'تم قبول حجز خدمة $serviceName لدى $washName بتاريخ $date الساعة $time',
      );
    } else if (status == 'مرفوض') {
      await createCustomerNotification(
        customerId: customerId,
        bookingId: bookingId,
        title: 'تم رفض حجزك',
        body:
            'تم رفض حجز خدمة $serviceName لدى $washName بتاريخ $date الساعة $time',
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('تم تحديث حالة الحجز إلى $status')));
  }

  Stream<int> unreadNotificationsCountStream() async* {
    final washId = SessionService.currentWashId ?? '';

    if (washId.isEmpty) {
      yield 0;
      return;
    }

    await for (final notificationSnapshot
        in FirebaseFirestore.instance
            .collection('notifications')
            .where('isActive', isEqualTo: true)
            .snapshots()) {
      final notifications = notificationSnapshot.docs.where((doc) {
        final data = doc.data();
        final target = data['target']?.toString() ?? 'all';
        return target == 'all' || target == 'washes';
      }).toList();

      if (notifications.isEmpty) {
        yield 0;
        continue;
      }

      final readSnapshot = await FirebaseFirestore.instance
          .collection('notification_reads')
          .where('userId', isEqualTo: washId)
          .where('userType', isEqualTo: 'wash')
          .get();

      final readIds = readSnapshot.docs
          .map((doc) => doc.data()['notificationId']?.toString() ?? '')
          .toSet();

      final unreadCount = notifications
          .where((doc) => !readIds.contains(doc.id))
          .length;

      yield unreadCount;
    }
  }

  Widget notificationButton(BuildContext context) {
    return StreamBuilder<int>(
      stream: unreadNotificationsCountStream(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WashNotificationsScreen(),
                  ),
                );
              },
            ),
            if (count > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    SessionService.currentWashId = '';
    SessionService.currentWashName = '';

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Color statusColor(String status) {
    if (status == 'مقبول') return Colors.green;
    if (status == 'مرفوض') return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(SessionService.currentWashName ?? 'لوحة المغسلة'),
          centerTitle: true,
          actions: [
            notificationButton(context),
            IconButton(
              icon: const Icon(Icons.design_services),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ServiceManagementScreen(),
                  ),
                );
              },
            ),
            IconButton(icon: const Icon(Icons.logout), onPressed: logout),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('washId', isEqualTo: SessionService.currentWashId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('لا توجد طلبات حالياً'));
            }

            final bookings = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final data = booking.data() as Map<String, dynamic>;
                final status = data['status']?.toString() ?? 'بانتظار الموافقة';

                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.calendar_month),
                          title: Text(data['customerName'] ?? ''),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('الخدمة: ${data['serviceName'] ?? ''}'),
                              Text('التاريخ: ${data['date'] ?? ''}'),
                              Text('الوقت: ${data['time'] ?? ''}'),
                              if (data['hasDiscount'] == true) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'كود الخصم: ${data['couponCode'] ?? ''}',
                                  style: const TextStyle(color: Colors.green),
                                ),
                                Text(
                                  'نسبة الخصم: ${data['discountPercentage'] ?? 0}%',
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Chip(
                          label: Text(status),
                          backgroundColor: statusColor(status),
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 15),
                        if (status == 'بانتظار الموافقة') ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    updateStatus(booking.id, 'مقبول', data);
                                  },
                                  child: const Text('قبول'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () {
                                    updateStatus(booking.id, 'مرفوض', data);
                                  },
                                  child: const Text('رفض'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
