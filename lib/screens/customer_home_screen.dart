import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../main.dart';
import '../services/session_service.dart';
import '../services/ads_service.dart';
import 'my_bookings_screen.dart';
import 'wash_list_screen.dart';
import 'customer_notifications_screen.dart';
import 'service_selection_screen.dart';

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

  Widget paidAdCard(BuildContext context, Map<String, dynamic> adData) {
    final title = adData['title']?.toString() ?? 'عرض خاص';
    final body = adData['body']?.toString() ?? '';
    final washId = adData['washId']?.toString() ?? '';
    final washName = adData['washName']?.toString() ?? 'مغسلة';
    final startDate = AdsService.formatDate(adData['startAt']);
    final endDate = AdsService.formatDate(adData['endAt']);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'إعلان ممول',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  washName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.local_car_wash, color: Colors.orange),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.4)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range, size: 18, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'مدة العرض: $startDate إلى $endDate',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: washId.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceSelectionScreen(
                            washId: washId,
                            washName: washName,
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.arrow_back),
              label: const Text('احجز الآن'),
            ),
          ),
        ],
      ),
    );
  }

  Widget paidAdsSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('type', isEqualTo: 'paid_ad')
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
          return AdsService.isCurrentlyActivePaidAd(doc.data());
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
              'عروض ممولة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...ads.map((doc) => paidAdCard(context, doc.data())),
            const SizedBox(height: 8),
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
