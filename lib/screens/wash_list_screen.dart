import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/ads_service.dart';
import '../services/working_hours_service.dart';
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
    final title = adData['title']?.toString() ?? '';
    final body = adData['body']?.toString() ?? '';
    final washId = adData['washId']?.toString() ?? '';
    final washName = adData['washName']?.toString() ?? 'مغسلة';
    final startDate = formatAdDate(adData['startAt']);
    final endDate = formatAdDate(adData['endAt']);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إعلان ممول',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(body),
          const SizedBox(height: 8),
          Text('المغسلة: $washName'),
          Text('مدة العرض: $startDate إلى $endDate'),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
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
              child: const Text('احجز الآن'),
            ),
          ),
        ],
      ),
    );
  }

  Color washStatusColor(String statusText) {
    if (statusText.contains('مفتوحة')) return Colors.green;
    if (statusText.contains('تفتح')) return Colors.orange;
    return Colors.red;
  }

  Widget washCard(
    BuildContext context,
    QueryDocumentSnapshot wash,
    Map<String, dynamic> data,
    bool isSponsored,
  ) {
    final washName =
        data['washName']?.toString() ?? data['name']?.toString() ?? '';
    final statusText = WorkingHoursService.washStatusText(data);
    final canBook = WorkingHoursService.isOpenAt(
      washData: data,
      dateTime: DateTime.now(),
    );

    return Card(
      color: isSponsored ? Colors.amber.shade50 : null,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          Icons.local_car_wash,
          color: isSponsored ? Colors.orange : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                washName,
                style: TextStyle(
                  fontWeight: isSponsored ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSponsored)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ممول',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${data['city']?.toString() ?? ''} - ${data['washType']?.toString() ?? ''}',
            ),
            const SizedBox(height: 4),
            Text(
              statusText,
              style: TextStyle(
                color: washStatusColor(statusText),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: canBook
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
          child: const Text('اختيار'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اختر المغسلة'), centerTitle: true),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('washes')
              .where('status', isEqualTo: 'approved')
              .snapshots(),
          builder: (context, washesSnapshot) {
            if (washesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (washesSnapshot.hasError) {
              return Center(
                child: Text('خطأ في تحميل المغاسل: ${washesSnapshot.error}'),
              );
            }

            if (!washesSnapshot.hasData || washesSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text('لا توجد مغاسل متاحة حالياً'));
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

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'المغاسل المتاحة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
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
        ),
      ),
    );
  }
}
