import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'service_selection_screen.dart';

class WashListScreen extends StatelessWidget {
  const WashListScreen({super.key});

  bool isPaidAdActive(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';
    final target = data['target']?.toString() ?? '';
    final isActive = data['isActive'] == true;

    return type == 'paid_ad' &&
        isActive &&
        (target == 'customers' || target == 'all');
  }

  Widget paidAdCard(Map<String, dynamic> adData) {
    return Card(
      color: Colors.amber.shade50,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.campaign, color: Colors.orange),
        title: Text(
          adData['title']?.toString() ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${adData['body']?.toString() ?? ''}\n'
          'إعلان ممول - ${adData['washName']?.toString() ?? ''}',
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget washCard(
    BuildContext context,
    QueryDocumentSnapshot wash,
    Map<String, dynamic> data,
    bool isSponsored,
  ) {
    final washName =
        data['washName']?.toString() ?? data['name']?.toString() ?? '';

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
        subtitle: Text(
          '${data['city']?.toString() ?? ''} - ${data['washType']?.toString() ?? ''}',
        ),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ServiceSelectionScreen(washId: wash.id, washName: washName),
              ),
            );
          },
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

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .snapshots(),
              builder: (context, adsSnapshot) {
                final adsDocs = adsSnapshot.data?.docs ?? [];

                final paidAds = adsDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return isPaidAdActive(data);
                }).toList();

                final sponsoredWashIds = paidAds
                    .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['washId']?.toString() ?? '';
                    })
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
                    if (paidAds.isNotEmpty) ...[
                      const Text(
                        'إعلانات ممولة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...paidAds.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return paidAdCard(data);
                      }),
                      const SizedBox(height: 10),
                    ],
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
