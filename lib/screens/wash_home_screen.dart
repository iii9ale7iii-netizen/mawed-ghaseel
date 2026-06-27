import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../main.dart';
import '../services/booking_status_service.dart';
import '../services/session_service.dart';
import '../theme/app_glass_ui.dart';
import 'service_management_screen.dart';
import 'wash_notifications_screen.dart';
import 'working_hours_screen.dart';

class WashHomeScreen extends StatefulWidget {
  const WashHomeScreen({super.key});

  @override
  State<WashHomeScreen> createState() => _WashHomeScreenState();
}

class _WashHomeScreenState extends State<WashHomeScreen> {
  String selectedStatusFilter = 'all';

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
    final normalizedStatus = BookingStatusService.normalize(status);

    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({'status': normalizedStatus});

    final customerId = bookingData['customerId']?.toString() ?? '';
    final washName = SessionService.currentWashName ?? 'المغسلة';
    final serviceName = bookingData['serviceName']?.toString() ?? '';
    final date = bookingData['date']?.toString() ?? '';
    final time = bookingData['time']?.toString() ?? '';

    if (BookingStatusService.isAccepted(normalizedStatus)) {
      await createCustomerNotification(
        customerId: customerId,
        bookingId: bookingId,
        title: 'تم قبول حجزك',
        body:
            'تم قبول حجز خدمة $serviceName لدى $washName بتاريخ $date الساعة $time',
      );
    } else if (BookingStatusService.isRejected(normalizedStatus)) {
      await createCustomerNotification(
        customerId: customerId,
        bookingId: bookingId,
        title: 'تم رفض حجزك',
        body:
            'تم رفض حجز خدمة $serviceName لدى $washName بتاريخ $date الساعة $time',
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم تحديث حالة الحجز إلى ${BookingStatusService.label(normalizedStatus)}',
        ),
      ),
    );
  }

  Stream<int> unreadNotificationsCountStream() async* {
    final washId = SessionService.currentWashId ?? '';

    if (washId.isEmpty) {
      yield 0;
      return;
    }

    await for (final notificationSnapshot in FirebaseFirestore.instance
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

      yield notifications.where((doc) => !readIds.contains(doc.id)).length;
    }
  }

  Widget notificationButton(BuildContext context) {
    return StreamBuilder<int>(
      stream: unreadNotificationsCountStream(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            AppCircleIconButton(
              icon: Icons.notifications_rounded,
              tooltip: 'الإشعارات',
              onTap: () {
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
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  constraints: const BoxConstraints(minWidth: 19),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
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

  bool matchesStatusFilter(String status) {
    if (selectedStatusFilter == 'pending') {
      return BookingStatusService.isPending(status);
    }
    if (selectedStatusFilter == 'accepted') {
      return BookingStatusService.isAccepted(status);
    }
    if (selectedStatusFilter == 'rejected') {
      return BookingStatusService.isRejected(status);
    }
    return true;
  }

  int compareBookingsByCreatedAt(
    QueryDocumentSnapshot first,
    QueryDocumentSnapshot second,
  ) {
    final firstData = first.data() as Map<String, dynamic>;
    final secondData = second.data() as Map<String, dynamic>;
    final firstCreatedAt = firstData['createdAt'];
    final secondCreatedAt = secondData['createdAt'];

    if (firstCreatedAt is Timestamp && secondCreatedAt is Timestamp) {
      return secondCreatedAt.compareTo(firstCreatedAt);
    }

    if (firstCreatedAt is Timestamp) return -1;
    if (secondCreatedAt is Timestamp) return 1;
    return 0;
  }

  Widget managementButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle(
          title: 'إدارة المغسلة',
          subtitle: 'تحكم بالخدمات وساعات استقبال الحجوزات',
          icon: Icons.dashboard_customize_rounded,
        ),
        const SizedBox(height: 12),
        AppActionCard(
          title: 'إدارة الخدمات',
          subtitle: 'إضافة الخدمات وتعديل قائمة الأسعار والمدة.',
          icon: Icons.design_services_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ServiceManagementScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        AppActionCard(
          title: 'أوقات العمل',
          subtitle: 'تحديد أيام العمل وساعات استقبال الحجوزات.',
          icon: Icons.access_time_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkingHoursScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value, IconData icon) {
    final selected = selectedStatusFilter == value;

    return ChoiceChip(
      selected: selected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: selected ? Colors.white : AppGlassUi.primary,
          ),
          const SizedBox(width: 5),
          Text(label),
        ],
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppGlassUi.darkText,
        fontWeight: FontWeight.w800,
      ),
      selectedColor: AppGlassUi.primary,
      backgroundColor: Colors.white.withValues(alpha: 0.78),
      side: const BorderSide(color: Color(0xFFD9ECFF)),
      onSelected: (_) {
        setState(() {
          selectedStatusFilter = value;
        });
      },
    );
  }

  Widget bookingFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _filterChip('الكل', 'all', Icons.list_alt_rounded),
          const SizedBox(width: 8),
          _filterChip('بانتظار', 'pending', Icons.hourglass_top_rounded),
          const SizedBox(width: 8),
          _filterChip('مقبولة', 'accepted', Icons.check_circle_rounded),
          const SizedBox(width: 8),
          _filterChip('مرفوضة', 'rejected', Icons.cancel_rounded),
        ],
      ),
    );
  }

  Widget bookingCard(QueryDocumentSnapshot booking) {
    final data = booking.data() as Map<String, dynamic>;
    final status = data['status']?.toString() ?? BookingStatusService.pending;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppGlassCard(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppActionIcon(icon: Icons.calendar_month_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data['customerName']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppGlassUi.darkText,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: AppStatusChip(
                    label: BookingStatusService.label(status),
                    color: BookingStatusService.color(status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AppInfoRow(
              icon: Icons.design_services_rounded,
              text: "الخدمة: ${data['serviceName'] ?? ''}",
            ),
            AppInfoRow(
              icon: Icons.date_range_rounded,
              text: "التاريخ: ${data['date'] ?? ''}",
            ),
            AppInfoRow(
              icon: Icons.access_time_rounded,
              text: "الوقت: ${data['time'] ?? ''}",
            ),
            if (data['hasDiscount'] == true) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تم تطبيق خصم',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text("كود الخصم: ${data['couponCode'] ?? ''}"),
                    Text("نسبة الخصم: ${data['discountPercentage'] ?? 0}%"),
                  ],
                ),
              ),
            ],
            if (BookingStatusService.isPending(status)) ...[
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: AppGradientButton(
                      title: 'قبول',
                      icon: Icons.check_rounded,
                      onTap: () => updateStatus(
                        booking.id,
                        BookingStatusService.accepted,
                        data,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppGradientButton(
                      title: 'رفض',
                      icon: Icons.close_rounded,
                      danger: true,
                      onTap: () => updateStatus(
                        booking.id,
                        BookingStatusService.rejected,
                        data,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget bookingsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('washId', isEqualTo: SessionService.currentWashId)
          .snapshots(),
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
            title: 'لا توجد طلبات حالياً',
            icon: Icons.event_busy_rounded,
          );
        }

        final bookings = snapshot.data!.docs.where((booking) {
          final data = booking.data() as Map<String, dynamic>;
          final status = data['status']?.toString() ?? BookingStatusService.pending;
          return matchesStatusFilter(status);
        }).toList();

        bookings.sort(compareBookingsByCreatedAt);

        if (bookings.isEmpty) {
          return const AppEmptyState(
            title: 'لا توجد حجوزات ضمن هذا التصنيف',
            icon: Icons.filter_alt_off_rounded,
          );
        }

        return Column(children: bookings.map(bookingCard).toList());
      },
    );
  }

  Widget _header() {
    final washName = SessionService.currentWashName ?? 'لوحة المغسلة';

    return AppGlassCard(
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo_mawed_ghaseel.png',
            width: 58,
            height: 58,
            fit: BoxFit.contain,
          ),
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
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'تابع الطلبات وأدر خدمات المغسلة من مكان واحد.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppGlassUi.mutedText,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              title: 'لوحة المغسلة',
              actions: [
                AppCircleIconButton(
                  icon: Icons.logout_rounded,
                  tooltip: 'تسجيل الخروج',
                  onTap: logout,
                ),
                notificationButton(context),
              ],
            ),
            const SizedBox(height: 18),
            _header(),
            const SizedBox(height: 18),
            managementButtons(),
            const SizedBox(height: 18),
            const AppSectionTitle(
              title: 'طلبات الحجز',
              subtitle: 'راجع الحجوزات الجديدة وقم بقبولها أو رفضها',
              icon: Icons.assignment_rounded,
            ),
            const SizedBox(height: 12),
            bookingFilters(),
            const SizedBox(height: 12),
            bookingsList(),
          ],
        ),
      ),
    );
  }
}
