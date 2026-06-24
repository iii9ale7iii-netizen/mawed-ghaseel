import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/session_service.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});

  @override
  State<ServiceManagementScreen> createState() =>
      _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final durationController = TextEditingController();

  Future<void> addService() async {
    if (nameController.text.isEmpty ||
        priceController.text.isEmpty ||
        durationController.text.isEmpty) {
      return;
    }

    await FirebaseFirestore.instance.collection('services').add({
      'washId': SessionService.currentWashId,
      'serviceName': nameController.text.trim(),
      'price': double.parse(priceController.text),
      'durationMinutes': int.parse(durationController.text),
      'createdAt': Timestamp.now(),
    });

    nameController.clear();
    priceController.clear();
    durationController.clear();
  }

  Future<void> deleteService(String serviceId) async {
    await FirebaseFirestore.instance
        .collection('services')
        .doc(serviceId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة الخدمات'), centerTitle: true),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('services')
                    .where('washId', isEqualTo: SessionService.currentWashId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final services = snapshot.data!.docs;

                  if (services.isEmpty) {
                    return const Center(child: Text('لا توجد خدمات'));
                  }

                  return ListView.builder(
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      final data = service.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(data['serviceName'] ?? ''),
                          subtitle: Text(
                            '${data['price']} ريال - ${data['durationMinutes']} دقيقة',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              deleteService(service.id);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const Divider(),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الخدمة',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'السعر',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'مدة الخدمة بالدقائق',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: addService,
                      child: const Text('إضافة خدمة'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
