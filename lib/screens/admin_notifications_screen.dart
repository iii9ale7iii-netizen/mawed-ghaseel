import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  String target = 'all';
  bool isLoading = false;

  Future<void> addNotification() async {
    if (titleController.text.isEmpty || bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال العنوان ونص الإعلان')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'title': titleController.text.trim(),
      'body': bodyController.text.trim(),
      'target': target,
      'createdAt': Timestamp.now(),
      'isActive': true,
    });

    titleController.clear();
    bodyController.clear();

    setState(() {
      target = 'all';
      isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إضافة الإعلان بنجاح')));
    }
  }

  Future<void> deleteNotification(String id) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(id)
        .delete();
  }

  String targetText(String value) {
    if (value == 'customers') return 'العملاء';
    if (value == 'washes') return 'المغاسل';
    return 'الكل';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدارة الإعلانات'), centerTitle: true),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان الإعلان',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: bodyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'نص الإعلان',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: target,
              decoration: const InputDecoration(
                labelText: 'الفئة المستهدفة',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('الكل')),
                DropdownMenuItem(value: 'customers', child: Text('العملاء')),
                DropdownMenuItem(value: 'washes', child: Text('المغاسل')),
              ],
              onChanged: (value) {
                setState(() {
                  target = value!;
                });
              },
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : addNotification,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('إضافة الإعلان'),
              ),
            ),

            const Divider(height: 35),

            const Text(
              'الإعلانات الحالية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('لا توجد إعلانات حالياً'));
                }

                final notifications = snapshot.data!.docs;

                return Column(
                  children: notifications.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      child: ListTile(
                        title: Text(data['title'] ?? ''),
                        subtitle: Text(
                          '${data['body'] ?? ''}\nالفئة: ${targetText(data['target'] ?? 'all')}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteNotification(doc.id),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
