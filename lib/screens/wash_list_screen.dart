import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/ads_service.dart';
import '../services/working_hours_service.dart';
import '../theme/app_glass_ui.dart';
import 'service_selection_screen.dart';

class WashListScreen extends StatelessWidget {
  const WashListScreen({super.key});

  String formatAdDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    return '-';
  }

  Widget paidAdCard(BuildContext context, Map<String, dynamic> adData) {
    final title = adData['title']?.toString().trim() ?? '';
    final body = adData['body']?.toString().trim() ?? '';
    final washId = adData['washId']?.toString() ?? '';
    final washName = adData['washName']?.toString().trim() ?? 'مغسلة';
    final startDate = formatAdDate(adData['startAt']);
    final endDate = formatAdDate(adData['endAt']);

    return AppGlassCard(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFFFFBEB).withValues(alpha: 0.88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppActionIcon(icon: Icons.campaign_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppStatusChip(
                      label: 'إعلان ممول',
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title.isEmpty ? 'عرض خاص' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppGlassUi.darkText,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppGlassUi.mutedText,
                fontSize: 12.8,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 8),
          AppInfoRow(icon: Icons.local_car_wash_rounded, text: 'المغسلة: $washName'),
          AppInfoRow(
            icon: Icons.date_range_rounded,
            text: 'مدة العرض: $startDate إلى $endDate',
          ),
          const SizedBox(height: 14),
          AppGradientButton(
            title: 'احجز الآن',
            icon: Icons.arrow_back_rounded,
            onTap: washId.isEmpty
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
          ),
        ],
      ),
    );
  }

  Color washStatusColor(String statusText) {
    if (statusText.contains('مفتوحة') || statusText.contains('ظ…ظپطھظˆط­ط©')) {
      return Colors.green;
    }
    if (statusText.contains('تفتح') || statusText.contains('طھظپطھط­')) {
      return Colors.orange;
    }
    return Colors.red;
  }

  Widget washCard(
    BuildContext context,
    QueryDocumentSnapshot wash,
    Map<String, dynamic> data,
    bool isSponsored,
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
        color: isSponsored
            ? const Color(0xFFFFFBEB).withValues(alpha: 0.88)
            : null,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppActionIcon(
                  icon: isSponsored
                      ? Icons.workspace_premium_rounded
                      : Icons.local_car_wash_rounded,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              washName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppGlassUi.darkText,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (isSponsored) ...[
                            const SizedBox(width: 8),
                            const AppStatusChip(
                              label: 'ممول',
                              color: Color(0xFFB45309),
                            ),
                          ],
                        ],
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

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('type', isEqualTo: 'paid_ad')
              .snapshots(),
          builder: (context, adsSnapshot) {
            final adsDocs = adsSnapshot.data?.docs ?? [];
            final paidAds = adsDocs.where((doc) {
              return AdsService.isCurrentlyActivePaidAd(doc.data());
            }).toList();

            final sponsoredWashIds = paidAds
                .map((doc) => doc.data()['washId']?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .toSet();

            final sortedWashes = [...washes];
            sortedWashes.sort((a, b) {
              final aSponsored = sponsoredWashIds.contains(a.id);
              final bSponsored = sponsoredWashIds.contains(b.id);

              if (aSponsored && !bSponsored) return -1;
              if (!aSponsored && bSponsored) return 1;
              return 0;
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSectionTitle(
                  title: 'المغاسل المتاحة',
                  subtitle: 'اختر المغسلة المناسبة واحجز خدمتك',
                  icon: Icons.local_car_wash_rounded,
                ),
                const SizedBox(height: 14),
                ...paidAds.take(2).map((ad) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: paidAdCard(context, ad.data()),
                    )),
                ...sortedWashes.map((wash) {
                  final data = wash.data() as Map<String, dynamic>;
                  final isSponsored = sponsoredWashIds.contains(wash.id);

                  return washCard(context, wash, data, isSponsored);
                }),
              ],
            );
          },
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
