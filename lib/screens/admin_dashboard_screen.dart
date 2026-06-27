import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/ads_service.dart';
import '../services/booking_status_service.dart';
import '../theme/app_glass_ui.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Widget statCard({
    required String title,
    required String value,
    required IconData icon,
    Color color = AppGlassUi.primary,
  }) {
    return AppGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppActionIcon(icon: icon, active: true),
          const SizedBox(height: 9),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppGlassUi.mutedText,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: AppSectionTitle(title: title, subtitle: '', icon: icon),
    );
  }

  Widget statsGrid(List<Widget> children) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.25,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: children,
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
            const AppGlassTopBar(
              title: 'لوحة الإحصائيات',
              leadingIcon: Icons.arrow_back_rounded,
              leadingTooltip: 'رجوع',
            ),
            const SizedBox(height: 18),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('washes').snapshots(),
              builder: (context, washesSnapshot) {
                if (!washesSnapshot.hasData) return const AppLoadingState();

                final washes = washesSnapshot.data!.docs;
                final totalWashes = washes.length;
                final approvedWashes = washes.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == 'approved';
                }).length;
                final pendingWashes = totalWashes - approvedWashes;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('customers')
                      .snapshots(),
                  builder: (context, customersSnapshot) {
                    if (!customersSnapshot.hasData) {
                      return const AppLoadingState();
                    }

                    final totalCustomers = customersSnapshot.data!.docs.length;

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('bookings')
                          .snapshots(),
                      builder: (context, bookingsSnapshot) {
                        if (!bookingsSnapshot.hasData) {
                          return const AppLoadingState();
                        }

                        final bookings = bookingsSnapshot.data!.docs;
                        final totalBookings = bookings.length;
                        final acceptedBookings = bookings.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return BookingStatusService.isAccepted(
                            data['status']?.toString() ?? '',
                          );
                        }).length;
                        final rejectedBookings = bookings.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return BookingStatusService.isRejected(
                            data['status']?.toString() ?? '',
                          );
                        }).length;
                        final pendingBookings = bookings.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return BookingStatusService.isPending(
                            data['status']?.toString() ?? '',
                          );
                        }).length;

                        return StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('notifications')
                              .where('type', isEqualTo: 'paid_ad')
                              .snapshots(),
                          builder: (context, adsSnapshot) {
                            if (!adsSnapshot.hasData) {
                              return const AppLoadingState();
                            }

                            final ads = adsSnapshot.data!.docs;
                            final totalAds = ads.length;
                            final activeAds = ads.where((doc) {
                              return AdsService.isCurrentlyActivePaidAd(
                                doc.data(),
                              );
                            }).length;
                            final endedAds = ads.where((doc) {
                              return AdsService.hasEnded(doc.data());
                            }).length;
                            final inactiveAds = ads.where((doc) {
                              final data = doc.data();
                              return data['isActive'] != true;
                            }).length;
                            var totalAdsRevenue = 0.0;
                            for (final doc in ads) {
                              totalAdsRevenue += AdsService.paidAmount(
                                doc.data(),
                              );
                            }

                            return StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('coupons')
                                  .snapshots(),
                              builder: (context, couponsSnapshot) {
                                if (!couponsSnapshot.hasData) {
                                  return const AppLoadingState();
                                }

                                final coupons = couponsSnapshot.data!.docs;
                                final totalCoupons = coupons.length;
                                final activeCoupons = coupons.where((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  return data['isActive'] == true;
                                }).length;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    sectionTitle(
                                      'المستخدمون والمغاسل',
                                      Icons.groups_rounded,
                                    ),
                                    statsGrid([
                                      statCard(
                                        title: 'العملاء',
                                        value: totalCustomers.toString(),
                                        icon: Icons.people_rounded,
                                      ),
                                      statCard(
                                        title: 'المغاسل',
                                        value: totalWashes.toString(),
                                        icon: Icons.local_car_wash_rounded,
                                      ),
                                      statCard(
                                        title: 'المعتمدة',
                                        value: approvedWashes.toString(),
                                        icon: Icons.verified_rounded,
                                        color: Colors.green,
                                      ),
                                      statCard(
                                        title: 'المعلقة',
                                        value: pendingWashes.toString(),
                                        icon: Icons.pending_actions_rounded,
                                        color: Colors.orange,
                                      ),
                                    ]),
                                    sectionTitle(
                                      'الحجوزات',
                                      Icons.calendar_month_rounded,
                                    ),
                                    statsGrid([
                                      statCard(
                                        title: 'إجمالي الحجوزات',
                                        value: totalBookings.toString(),
                                        icon: Icons.calendar_month_rounded,
                                      ),
                                      statCard(
                                        title: 'المقبولة',
                                        value: acceptedBookings.toString(),
                                        icon: Icons.check_circle_rounded,
                                        color: Colors.green,
                                      ),
                                      statCard(
                                        title: 'المرفوضة',
                                        value: rejectedBookings.toString(),
                                        icon: Icons.cancel_rounded,
                                        color: Colors.red,
                                      ),
                                      statCard(
                                        title: 'بانتظار الموافقة',
                                        value: pendingBookings.toString(),
                                        icon: Icons.hourglass_empty_rounded,
                                        color: Colors.orange,
                                      ),
                                    ]),
                                    sectionTitle(
                                      'الإعلانات الممولة',
                                      Icons.campaign_rounded,
                                    ),
                                    statsGrid([
                                      statCard(
                                        title: 'إجمالي الإعلانات',
                                        value: totalAds.toString(),
                                        icon: Icons.campaign_rounded,
                                      ),
                                      statCard(
                                        title: 'الإعلانات الفعالة',
                                        value: activeAds.toString(),
                                        icon: Icons.play_circle_rounded,
                                        color: Colors.green,
                                      ),
                                      statCard(
                                        title: 'الإعلانات المنتهية',
                                        value: endedAds.toString(),
                                        icon: Icons.timer_off_rounded,
                                        color: Colors.red,
                                      ),
                                      statCard(
                                        title: 'غير الفعالة',
                                        value: inactiveAds.toString(),
                                        icon: Icons.pause_circle_rounded,
                                        color: Colors.grey,
                                      ),
                                      statCard(
                                        title: 'إيرادات الإعلانات',
                                        value:
                                            '${totalAdsRevenue.toStringAsFixed(2)} ريال',
                                        icon: Icons.payments_rounded,
                                        color: Colors.green,
                                      ),
                                    ]),
                                    sectionTitle(
                                      'أكواد الخصم',
                                      Icons.discount_rounded,
                                    ),
                                    statsGrid([
                                      statCard(
                                        title: 'إجمالي الأكواد',
                                        value: totalCoupons.toString(),
                                        icon: Icons.discount_rounded,
                                      ),
                                      statCard(
                                        title: 'الأكواد الفعالة',
                                        value: activeCoupons.toString(),
                                        icon: Icons.check_rounded,
                                        color: Colors.green,
                                      ),
                                    ]),
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
          ],
        ),
      ),
    );
  }
}
