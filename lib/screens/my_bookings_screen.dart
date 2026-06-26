import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/session_service.dart';
import '../theme/app_glass_ui.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  String selectedStatusFilter = 'all';

  Future<void> cancelBooking(BuildContext context, String bookingId) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .delete();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إلغاء الحجز بنجاح')),
      );
    }
  }


  Future<void> confirmCancelBooking(
    BuildContext context,
    String bookingId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إلغاء الحجز'),
            content: const Text('هل أنت متأكد من إلغاء هذا الحجز؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('تراجع'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('إلغاء الحجز'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await cancelBooking(context, bookingId);
    }
  }

  Color statusColor(String status) {
    if (status == 'ظ…ظ‚ط¨ظˆظ„' || status == 'مقبول') return Colors.green;
    if (status == 'ظ…ط±ظپظˆط¶' || status == 'مرفوض') return Colors.red;
    return Colors.orange;
  }


  bool isPendingStatus(String status) {
    return status == 'بانتظار الموافقة' ||
        status == 'ط¨ط§ظ†طھط¸ط§ط± ط§ظ„ظ…ظˆط§ظپظ‚ط©' ||
        status == 'ط·آ¨ط·آ§ط¸â€ ط·ع¾ط·آ¸ط·آ§ط·آ± ط·آ§ط¸â€‍ط¸â€¦ط¸ث†ط·آ§ط¸ظ¾ط¸â€ڑط·آ©';
  }

  bool isAcceptedStatus(String status) {
    return status == 'مقبول' ||
        status == 'ظ…ظ‚ط¨ظˆظ„' ||
        status == 'ط¸â€¦ط¸â€ڑط·آ¨ط¸ث†ط¸â€‍';
  }

  bool isRejectedStatus(String status) {
    return status == 'مرفوض' ||
        status == 'ظ…ط±ظپظˆط¶' ||
        status == 'ط¸â€¦ط·آ±ط¸ظ¾ط¸ث†ط·آ¶';
  }

  bool matchesStatusFilter(String status) {
    if (selectedStatusFilter == 'pending') return isPendingStatus(status);
    if (selectedStatusFilter == 'accepted') return isAcceptedStatus(status);
    if (selectedStatusFilter == 'rejected') return isRejectedStatus(status);
    return true;
  }


  String statusLabel(String status) {
    if (isAcceptedStatus(status)) return 'مقبول';
    if (isRejectedStatus(status)) return 'مرفوض';
    return 'بانتظار الموافقة';
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

  Widget _bookingCard(
    BuildContext context,
    QueryDocumentSnapshot booking,
    Map<String, dynamic> data,
  ) {
    final status = data['status']?.toString() ?? 'بانتظار الموافقة';
    final hasDiscount = data['hasDiscount'] == true;
    final couponCode = data['couponCode']?.toString() ?? '';
    final discountPercentage = data['discountPercentage']?.toString() ?? '0';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppGlassCard(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppActionIcon(icon: Icons.local_car_wash_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data['washName']?.toString() ?? '',
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
                    label: statusLabel(status),
                    color: statusColor(status),
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
            if (hasDiscount) ...[
              const SizedBox(height: 12),
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
                    const Row(
                      children: [
                        Icon(Icons.local_offer_rounded, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'تم تطبيق خصم',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'كود الخصم: $couponCode',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('نسبة الخصم: $discountPercentage%'),
                  ],
                ),
              ),
            ],
            if (status == 'بانتظار الموافقة' ||
                status == 'ط¨ط§ظ†طھط¸ط§ط± ط§ظ„ظ…ظˆط§ظپظ‚ط©') ...[
              const SizedBox(height: 15),
              AppGradientButton(
                title: 'إلغاء الحجز',
                icon: Icons.cancel_rounded,
                danger: true,
                onTap: () => confirmCancelBooking(context, booking.id),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bookingsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('customerId', isEqualTo: SessionService.currentCustomerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingState();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const AppEmptyState(
            title: 'لا توجد حجوزات حالياً',
            icon: Icons.event_busy_rounded,
          );
        }

        final bookings = snapshot.data!.docs.where((booking) {
          final data = booking.data() as Map<String, dynamic>;
          final status = data['status']?.toString() ?? 'بانتظار الموافقة';
          return matchesStatusFilter(status);
        }).toList();

        if (bookings.isEmpty) {
          return const AppEmptyState(
            title: 'لا توجد حجوزات ضمن هذا التصنيف',
            icon: Icons.filter_alt_off_rounded,
          );
        }

        return Column(
          children: bookings.map((booking) {
            final data = booking.data() as Map<String, dynamic>;
            return _bookingCard(context, booking, data);
          }).toList(),
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
              title: 'مواعيدي',
              leadingIcon: Icons.arrow_back_rounded,
              leadingTooltip: 'رجوع',
            ),
            const SizedBox(height: 18),
            const AppSectionTitle(
              title: 'حجوزاتي',
              subtitle: 'تابع حالة المواعيد القادمة والسابقة',
              icon: Icons.event_available_rounded,
            ),
            const SizedBox(height: 12),
            bookingFilters(),
            const SizedBox(height: 12),
            _bookingsList(),
          ],
        ),
      ),
    );
  }
}
