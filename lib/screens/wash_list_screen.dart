import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/working_hours_service.dart';
import '../theme/app_glass_ui.dart';
import 'service_selection_screen.dart';

class WashListScreen extends StatelessWidget {
  const WashListScreen({super.key});

  Color washStatusColor(String statusText) {
    if (statusText.contains('مفتوحة')) {
      return Colors.green;
    }

    if (statusText.contains('تفتح')) {
      return Colors.orange;
    }

    return Colors.red;
  }

  Widget washCard(
    BuildContext context,
    QueryDocumentSnapshot wash,
    Map<String, dynamic> data,
  ) {
    final washName =
        data['washName']?.toString() ?? data['name']?.toString() ?? 'مغسلة';
    final statusText = WorkingHoursService.washStatusText(data);
    final statusColor = washStatusColor(statusText);
    final canBook = WorkingHoursService.isOpenAt(
      washData: data,
      dateTime: DateTime.now(),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppGlassCard(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppActionIcon(icon: Icons.local_car_wash_rounded),
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
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      AppInfoRow(
                        icon: Icons.location_city_rounded,
                        text:
                            "${data['city']?.toString() ?? ''} - ${data['washType']?.toString() ?? ''}",
                      ),
                      AppInfoRow(
                        icon: Icons.schedule_rounded,
                        text: statusText,
                        color: statusColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppGradientButton(
              title: 'اختيار',
              icon: Icons.arrow_back_rounded,
              onTap: canBook
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceSelectionScreen(
                            washId: wash.id,
                            washName: washName,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('washes')
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, washesSnapshot) {
        if (washesSnapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingState();
        }

        if (washesSnapshot.hasError) {
          return AppEmptyState(
            title: 'خطأ في تحميل المغاسل: ${washesSnapshot.error}',
            icon: Icons.error_outline_rounded,
          );
        }

        if (!washesSnapshot.hasData || washesSnapshot.data!.docs.isEmpty) {
          return const AppEmptyState(
            title: 'لا توجد مغاسل متاحة حالياً',
            icon: Icons.local_car_wash_outlined,
          );
        }

        final washes = washesSnapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionTitle(
              title: 'المغاسل المتاحة',
              subtitle: 'اختر المغسلة المناسبة واحجز خدمتك',
              icon: Icons.local_car_wash_rounded,
            ),
            const SizedBox(height: 14),
            ...washes.map((wash) {
              final data = wash.data() as Map<String, dynamic>;

              return washCard(context, wash, data);
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
      child: AppGlassScaffold(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppGlassTopBar(
              title: 'اختر المغسلة',
              leadingIcon: Icons.arrow_back_rounded,
              leadingTooltip: 'رجوع',
            ),
            const SizedBox(height: 18),
            _content(context),
          ],
        ),
      ),
    );
  }
}
