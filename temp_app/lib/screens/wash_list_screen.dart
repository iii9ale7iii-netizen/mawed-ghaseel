import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'service_selection_screen.dart';

class WashListScreen extends StatelessWidget {
  const WashListScreen({super.key});

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
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('لا توجد مغاسل متاحة حالياً'));
            }

            final washes = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: washes.length,
              itemBuilder: (context, index) {
                final wash = washes[index];
                final data = wash.data() as Map<String, dynamic>;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.local_car_wash),

                    title: Text(data['washName'] ?? ''),

                    subtitle: Text(
                      '${data['city'] ?? ''} - ${data['washType'] ?? ''}',
                    ),

                    trailing: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ServiceSelectionScreen(
                              washId: wash.id,
                              washName: data['washName'] ?? '',
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
