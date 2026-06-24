import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../main.dart';
import '../services/session_service.dart';
import 'my_bookings_screen.dart';
import 'wash_list_screen.dart';
import 'customer_notifications_screen.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    SessionService.currentCustomerId = '';
    SessionService.currentCustomerName = '';

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Stream<int> unreadNotificationsCountStream() async* {
    final customerId = SessionService.currentCustomerId ?? '';

    if (customerId.isEmpty) {
      yield 0;
      return;
    }

    await for (final notificationSnapshot
        in FirebaseFirestore.instance
            .collection('notifications')
            .where('isActive', isEqualTo: true)
            .where('target', whereIn: ['all', 'customers'])
            .snapshots()) {
      final notifications = notificationSnapshot.docs;

      if (notifications.isEmpty) {
        yield 0;
        continue;
      }

      final readSnapshot = await FirebaseFirestore.instance
          .collection('notification_reads')
          .where('userId', isEqualTo: customerId)
          .where('userType', isEqualTo: 'customer')
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
                    builder: (context) => const CustomerNotificationsScreen(),
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة العميل'),
          centerTitle: true,
          actions: [
            notificationButton(context),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WashListScreen(),
                      ),
                    );
                  },
                  child: const Text('حجز موعد جديد'),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyBookingsScreen(),
                      ),
                    );
                  },
                  child: const Text('مواعيدي'),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل الخروج'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
