import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_glass_ui.dart';
import 'booking_screen.dart';

class ServiceSelectionScreen extends StatelessWidget {
  final String washId;
  final String washName;

  const ServiceSelectionScreen({
    super.key,
    required this.washId,
    required this.washName,
  });

  Widget _serviceCard(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final serviceName = data['serviceName']?.toString() ?? '';
    final price = data['price']?.toString() ?? '';
    final duration = data['durationMinutes']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppGlassCard(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                const AppActionIcon(icon: Icons.design_services_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppGlassUi.darkText,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      AppInfoRow(
                        icon: Icons.payments_rounded,
                        text: '$price ريال - $duration دقيقة',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppGradientButton(
              title: 'اختيار الخدمة',
              icon: Icons.arrow_back_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingScreen(
                      washId: washId,
                      washName: washName,
                      serviceName: serviceName,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _servicesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('services')
          .where('washId', isEqualTo: washId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AppLoadingState();
        }

        final services = snapshot.data!.docs;

        if (services.isEmpty) {
          return const AppEmptyState(
            title: 'لا توجد خدمات متاحة حالياً',
            icon: Icons.design_services_outlined,
          );
        }

        return Column(
          children: services.map((service) {
            final data = service.data() as Map<String, dynamic>;
            return _serviceCard(context, data);
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
              title: washName,
              leadingIcon: Icons.arrow_back_rounded,
              leadingTooltip: 'رجوع',
            ),
            const SizedBox(height: 18),
            const AppSectionTitle(
              title: 'اختر الخدمة',
              subtitle: 'حدد الخدمة المناسبة قبل اختيار الموعد',
              icon: Icons.local_car_wash_rounded,
            ),
            const SizedBox(height: 12),
            _servicesList(),
          ],
        ),
      ),
    );
  }
}
