import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_screen.dart';

class ServiceSelectionScreen extends StatelessWidget {
  final String washId;
  final String washName;

  const ServiceSelectionScreen({
    super.key,
    required this.washId,
    required this.washName,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(washName), centerTitle: true),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('services')
              .where('washId', isEqualTo: washId)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final services = snapshot.data!.docs;

            if (services.isEmpty) {
              return const Center(child: Text('لا توجد خدمات متاحة حالياً'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                final data = service.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.local_car_wash),

                    title: Text(data['serviceName'] ?? ''),

                    subtitle: Text(
                      '${data['price']} ريال - ${data['durationMinutes']} دقيقة',
                    ),

                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingScreen(
                              washId: washId,
                              washName: washName,
                              serviceName: data['serviceName'] ?? '',
                            ),
                          ),
                        );
                      },
                      child: const Text('اختيار'),
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
