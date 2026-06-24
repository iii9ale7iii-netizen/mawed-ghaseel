import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/session_service.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  Future<void> cancelBooking(BuildContext context, String bookingId) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .delete();

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إلغاء الحجز بنجاح')));
    }
  }

  Color statusColor(String status) {
    if (status == 'مقبول') return Colors.green;
    if (status == 'مرفوض') return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('مواعيدي'), centerTitle: true),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('customerId', isEqualTo: SessionService.currentCustomerId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('لا توجد حجوزات حالياً'));
            }

            final bookings = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final data = booking.data() as Map<String, dynamic>;

                final status = data['status']?.toString() ?? 'بانتظار الموافقة';

                final hasDiscount = data['hasDiscount'] == true;
                final couponCode = data['couponCode']?.toString() ?? '';
                final discountPercentage =
                    data['discountPercentage']?.toString() ?? '0';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_car_wash),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                data['washName'] ?? '',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Chip(
                              label: Text(status),
                              backgroundColor: statusColor(status),
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Text('الخدمة: ${data['serviceName'] ?? ''}'),
                        Text('التاريخ: ${data['date'] ?? ''}'),
                        Text('الوقت: ${data['time'] ?? ''}'),

                        if (hasDiscount) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'تم تطبيق خصم',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text('كود الخصم: $couponCode'),
                                Text('نسبة الخصم: $discountPercentage%'),
                              ],
                            ),
                          ),
                        ],

                        if (status == 'بانتظار الموافقة') ...[
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () {
                                cancelBooking(context, booking.id);
                              },
                              child: const Text('إلغاء الحجز'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
