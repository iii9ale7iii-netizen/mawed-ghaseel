import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin_notifications_screen.dart';
import 'admin_coupons_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Widget statCard(String title, int value, {Color color = Colors.blue}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget adminButton(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(title),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة الأدمن'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();

                if (context.mounted) {
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              },
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('washes').snapshots(),
          builder: (context, washSnapshot) {
            if (!washSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final washes = washSnapshot.data!.docs;
            final totalWashes = washes.length;

            final approvedWashes = washes.where((wash) {
              final data = wash.data() as Map<String, dynamic>;
              return data['status'] == 'approved';
            }).length;

            final pendingWashes = washes.where((wash) {
              final data = wash.data() as Map<String, dynamic>;
              return data['status'] != 'approved';
            }).length;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('customers')
                  .snapshots(),
              builder: (context, customerSnapshot) {
                if (!customerSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final totalCustomers = customerSnapshot.data!.docs.length;

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .snapshots(),
                  builder: (context, bookingSnapshot) {
                    if (!bookingSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final bookings = bookingSnapshot.data!.docs;
                    final totalBookings = bookings.length;

                    final acceptedBookings = bookings.where((booking) {
                      final data = booking.data() as Map<String, dynamic>;
                      return data['status'] == 'مقبول';
                    }).length;

                    final rejectedBookings = bookings.where((booking) {
                      final data = booking.data() as Map<String, dynamic>;
                      return data['status'] == 'مرفوض';
                    }).length;

                    final pendingBookings = bookings.where((booking) {
                      final data = booking.data() as Map<String, dynamic>;
                      return data['status'] == 'بانتظار الموافقة';
                    }).length;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              adminButton(
                                context,
                                'إدارة الإعلانات',
                                Icons.notifications_active,
                                const AdminNotificationsScreen(),
                              ),
                              const SizedBox(height: 10),
                              adminButton(
                                context,
                                'إدارة أكواد الخصم',
                                Icons.discount,
                                const AdminCouponsScreen(),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(
                          height: 260,
                          child: GridView.count(
                            crossAxisCount: 2,
                            childAspectRatio: 1.8,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              statCard('العملاء', totalCustomers),
                              statCard('المغاسل', totalWashes),
                              statCard(
                                'المعتمدة',
                                approvedWashes,
                                color: Colors.green,
                              ),
                              statCard(
                                'المعلقة',
                                pendingWashes,
                                color: Colors.orange,
                              ),
                              statCard('الحجوزات', totalBookings),
                              statCard(
                                'المقبولة',
                                acceptedBookings,
                                color: Colors.green,
                              ),
                              statCard(
                                'المرفوضة',
                                rejectedBookings,
                                color: Colors.red,
                              ),
                              statCard(
                                'بانتظار الموافقة',
                                pendingBookings,
                                color: Colors.orange,
                              ),
                            ],
                          ),
                        ),

                        const Divider(),

                        Expanded(
                          child: ListView.builder(
                            itemCount: washes.length,
                            itemBuilder: (context, index) {
                              final wash = washes[index];
                              final data = wash.data() as Map<String, dynamic>;
                              final status =
                                  data['status']?.toString() ?? 'pending';

                              return Card(
                                margin: const EdgeInsets.all(10),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    children: [
                                      ListTile(
                                        title: Text(
                                          data['washName'] ?? 'بدون اسم',
                                        ),
                                        subtitle: Text(data['email'] ?? ''),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: status == 'approved'
                                                  ? Colors.green
                                                  : Colors.orange,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              status == 'approved'
                                                  ? 'معتمد'
                                                  : 'بانتظار الاعتماد',
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: status == 'approved'
                                                ? null
                                                : () async {
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('washes')
                                                        .doc(wash.id)
                                                        .update({
                                                          'status': 'approved',
                                                        });

                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'تم اعتماد المغسلة',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                            child: const Text('اعتماد'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            onPressed: () async {
                                              await FirebaseFirestore.instance
                                                  .collection('washes')
                                                  .doc(wash.id)
                                                  .delete();

                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'تم حذف المغسلة',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            child: const Text('حذف'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
