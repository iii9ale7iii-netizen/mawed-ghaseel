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

                final status = data['status'] ?? 'بانتظار الموافقة';

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

                            Chip(label: Text(status)),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Text('الخدمة: ${data['serviceName'] ?? ''}'),

                        Text('التاريخ: ${data['date'] ?? ''}'),

                        Text('الوقت: ${data['time'] ?? ''}'),

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
