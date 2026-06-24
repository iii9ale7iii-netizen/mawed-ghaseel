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

  bool _isPaidAd(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    return type == 'paid_ad' || data.containsKey('paidAmount');
  }

  bool _isActiveAd(Map<String, dynamic> data) {
    if (data.containsKey('isActive')) {
      return data['isActive'] == true;
    }
    return true;
  }

  bool _isAdVisibleByDate(Map<String, dynamic> data) {
    final now = DateTime.now();

    final startAt = data['startAt'];
    if (startAt is Timestamp && startAt.toDate().isAfter(now)) {
      return false;
    }

    final endAt = data['endAt'];
    if (endAt is Timestamp && endAt.toDate().isBefore(now)) {
      return false;
    }

    return true;
  }

  bool _isAdForCustomers(Map<String, dynamic> data) {
    final target = data['target']?.toString() ?? '';

    if (target.isEmpty) return true;

    return target == 'all' ||
        target == 'customers' ||
        target == 'customer' ||
        target == 'specific_customer' ||
        target == 'العملاء' ||
        target == 'الكل';
  }

  Stream<int> unreadNotificationsCountStream() async* {
    final customerId = SessionService.currentCustomerId ?? '';

    if (customerId.isEmpty) {
      yield 0;
      return;
    }

    await for (final notificationSnapshot
        in FirebaseFirestore.instance.collection('notifications').snapshots()) {
      final notifications = notificationSnapshot.docs.where((doc) {
        final data = doc.data();

        if (data['isActive'] == false) return false;

        final target = data['target']?.toString() ?? '';

        return target == 'all' ||
            target == 'customers' ||
            target == 'customer' ||
            target == 'specific_customer' ||
            target == 'العملاء' ||
            target == 'الكل' ||
            target.isEmpty;
      }).toList();

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

  Widget paidAdsSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'خطأ في تحميل الإعلانات: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];

        final ads = allDocs.where((doc) {
          final data = doc.data();

          return _isPaidAd(data) &&
              _isActiveAd(data) &&
              _isAdVisibleByDate(data) &&
              _isAdForCustomers(data);
        }).toList();

        ads.sort((a, b) {
          final aDate = a.data()['createdAt'];
          final bDate = b.data()['createdAt'];

          if (aDate is Timestamp && bDate is Timestamp) {
            return bDate.compareTo(aDate);
          }

          return 0;
        });

        if (ads.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إعلانات ممولة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 145,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ads.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final data = ads[index].data();

                  final title = data['title']?.toString() ?? 'إعلان';
                  final body = data['body']?.toString() ?? '';
                  final washName =
                      data['washName']?.toString() ?? 'مغسلة معلنة';

                  return Container(
                    width: 280,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.shade400),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'إعلان ممول',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                washName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            body,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
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
          child: ListView(
            children: [
              paidAdsSection(),
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
