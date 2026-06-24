import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../main.dart';
import '../services/session_service.dart';
import 'service_management_screen.dart';

class WashHomeScreen extends StatefulWidget {
  const WashHomeScreen({super.key});

  @override
  State<WashHomeScreen> createState() => _WashHomeScreenState();
}

class _WashHomeScreenState extends State<WashHomeScreen> {
  Future<void> updateStatus(String bookingId, String status) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({'status': status});
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(SessionService.currentWashName ?? 'لوحة المغسلة'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.design_services),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ServiceManagementScreen(),
                  ),
                );
              },
            ),
            IconButton(icon: const Icon(Icons.logout), onPressed: logout),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .where('washId', isEqualTo: SessionService.currentWashId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('لا توجد طلبات حالياً'));
            }

            final bookings = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                final data = booking.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.calendar_month),
                          title: Text(data['customerName'] ?? ''),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('الخدمة: ${data['serviceName']}'),
                              Text('التاريخ: ${data['date']}'),
                              Text('الوقت: ${data['time']}'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        Chip(label: Text(data['status'] ?? 'بانتظار الموافقة')),

                        const SizedBox(height: 15),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  updateStatus(booking.id, 'مقبول');
                                },
                                child: const Text('قبول'),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  updateStatus(booking.id, 'مرفوض');
                                },
                                child: const Text('رفض'),
                              ),
                            ),
                          ],
                        ),
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
