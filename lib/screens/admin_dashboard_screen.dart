import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/ads_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Widget statCard({
    required String title,
    required String value,
    required IconData icon,
    Color color = Colors.blue,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('لوحة الإحصائيات'), centerTitle: true),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('washes').snapshots(),
          builder: (context, washesSnapshot) {
            if (!washesSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final washes = washesSnapshot.data!.docs;

            final totalWashes = washes.length;
            final approvedWashes = washes.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'approved';
            }).length;

            final pendingWashes = washes.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] != 'approved';
            }).length;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('customers')
                  .snapshots(),
              builder: (context, customersSnapshot) {
                if (!customersSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final totalCustomers = customersSnapshot.data!.docs.length;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .snapshots(),
                  builder: (context, bookingsSnapshot) {
                    if (!bookingsSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final bookings = bookingsSnapshot.data!.docs;
                    final totalBookings = bookings.length;

                    final acceptedBookings = bookings.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['status'] == 'مقبول';
                    }).length;

                    final rejectedBookings = bookings.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['status'] == 'مرفوض';
                    }).length;

                    final pendingBookings = bookings.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['status'] == 'بانتظار الموافقة';
                    }).length;

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('notifications')
                          .where('type', isEqualTo: 'paid_ad')
                          .snapshots(),
                      builder: (context, adsSnapshot) {
                        if (!adsSnapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final ads = adsSnapshot.data!.docs;

                        final totalAds = ads.length;

                        final activeAds = ads.where((doc) {
                          return AdsService.isCurrentlyActivePaidAd(doc.data());
                        }).length;

                        final endedAds = ads.where((doc) {
                          return AdsService.hasEnded(doc.data());
                        }).length;

                        final inactiveAds = ads.where((doc) {
                          final data = doc.data();
                          return data['isActive'] != true;
                        }).length;

                        double totalAdsRevenue = 0;
                        for (final doc in ads) {
                          totalAdsRevenue += AdsService.paidAmount(doc.data());
                        }

                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('coupons')
                              .snapshots(),
                          builder: (context, couponsSnapshot) {
                            if (!couponsSnapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final coupons = couponsSnapshot.data!.docs;
                            final totalCoupons = coupons.length;

                            final activeCoupons = coupons.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return data['isActive'] == true;
                            }).length;

                            return ListView(
                              padding: const EdgeInsets.all(16),
                              children: [
                                sectionTitle('المستخدمون والمغاسل'),
                                GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  childAspectRatio: 1.45,
                                  children: [
                                    statCard(
                                      title: 'العملاء',
                                      value: totalCustomers.toString(),
                                      icon: Icons.people,
                                    ),
                                    statCard(
                                      title: 'المغاسل',
                                      value: totalWashes.toString(),
                                      icon: Icons.local_car_wash,
                                    ),
                                    statCard(
                                      title: 'المعتمدة',
                                      value: approvedWashes.toString(),
                                      icon: Icons.verified,
                                      color: Colors.green,
                                    ),
                                    statCard(
                                      title: 'المعلقة',
                                      value: pendingWashes.toString(),
                                      icon: Icons.pending_actions,
                                      color: Colors.orange,
                                    ),
                                  ],
                                ),

                                sectionTitle('الحجوزات'),
                                GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  childAspectRatio: 1.45,
                                  children: [
                                    statCard(
                                      title: 'إجمالي الحجوزات',
                                      value: totalBookings.toString(),
                                      icon: Icons.calendar_month,
                                    ),
                                    statCard(
                                      title: 'المقبولة',
                                      value: acceptedBookings.toString(),
                                      icon: Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    statCard(
                                      title: 'المرفوضة',
                                      value: rejectedBookings.toString(),
                                      icon: Icons.cancel,
                                      color: Colors.red,
                                    ),
                                    statCard(
                                      title: 'بانتظار الموافقة',
                                      value: pendingBookings.toString(),
                                      icon: Icons.hourglass_empty,
                                      color: Colors.orange,
                                    ),
                                  ],
                                ),

                                sectionTitle('الإعلانات الممولة'),
                                GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  childAspectRatio: 1.45,
                                  children: [
                                    statCard(
                                      title: 'إجمالي الإعلانات',
                                      value: totalAds.toString(),
                                      icon: Icons.campaign,
                                    ),
                                    statCard(
                                      title: 'الإعلانات الفعالة',
                                      value: activeAds.toString(),
                                      icon: Icons.play_circle,
                                      color: Colors.green,
                                    ),
                                    statCard(
                                      title: 'الإعلانات المنتهية',
                                      value: endedAds.toString(),
                                      icon: Icons.timer_off,
                                      color: Colors.red,
                                    ),
                                    statCard(
                                      title: 'غير الفعالة',
                                      value: inactiveAds.toString(),
                                      icon: Icons.pause_circle,
                                      color: Colors.grey,
                                    ),
                                    statCard(
                                      title: 'إيرادات الإعلانات',
                                      value:
                                          '${totalAdsRevenue.toStringAsFixed(2)} ريال',
                                      icon: Icons.payments,
                                      color: Colors.green,
                                    ),
                                  ],
                                ),

                                sectionTitle('أكواد الخصم'),
                                GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  childAspectRatio: 1.45,
                                  children: [
                                    statCard(
                                      title: 'إجمالي الأكواد',
                                      value: totalCoupons.toString(),
                                      icon: Icons.discount,
                                    ),
                                    statCard(
                                      title: 'الأكواد الفعالة',
                                      value: activeCoupons.toString(),
                                      icon: Icons.check,
                                      color: Colors.green,
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );
                      },
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
