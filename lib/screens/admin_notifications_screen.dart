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
  final paidAmountController = TextEditingController();

  String target = 'customers';
  String selectedWashId = '';
  String selectedWashName = '';
  bool isLoading = false;

  Future<void> addPaidAd() async {
    if (titleController.text.trim().isEmpty ||
        bodyController.text.trim().isEmpty ||
        selectedWashId.isEmpty ||
        paidAmountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى تعبئة العنوان والنص واختيار المغسلة والمبلغ'),
        ),
      );
      return;
    }

    final paidAmount = double.tryParse(paidAmountController.text.trim());

    if (paidAmount == null || paidAmount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى إدخال مبلغ صحيح')));
      return;
    }

    setState(() {
      isLoading = true;
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'title': titleController.text.trim(),
      'body': bodyController.text.trim(),
      'target': target,
      'type': 'paid_ad',
      'washId': selectedWashId,
      'washName': selectedWashName,
      'paidAmount': paidAmount,
      'isActive': true,
      'createdAt': Timestamp.now(),
    });

    titleController.clear();
    bodyController.clear();
    paidAmountController.clear();

    setState(() {
      target = 'customers';
      selectedWashId = '';
      selectedWashName = '';
      isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة الإعلان المدفوع بنجاح')),
      );
    }
  }

  Future<void> toggleNotification(String id, bool currentValue) async {
    await FirebaseFirestore.instance.collection('notifications').doc(id).update(
      {'isActive': !currentValue},
    );
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

  String typeText(String value) {
    if (value == 'paid_ad') return 'إعلان مدفوع';
    return 'إعلان عام';
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    paidAmountController.dispose();
    super.dispose();
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
            const Text(
              'إضافة إعلان مدفوع للمغاسل',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('washes')
                  .where('status', isEqualTo: 'approved')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final washes = snapshot.data!.docs;

                if (washes.isEmpty) {
                  return const Text('لا توجد مغاسل معتمدة حالياً');
                }

                return DropdownButtonFormField<String>(
                  value: selectedWashId.isEmpty ? null : selectedWashId,
                  decoration: const InputDecoration(
                    labelText: 'اختر المغسلة المعلنة',
                    border: OutlineInputBorder(),
                  ),
                  items: washes.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final washName =
                        data['washName']?.toString() ??
                        data['name']?.toString() ??
                        'مغسلة بدون اسم';

                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(washName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    final selectedDoc = washes.firstWhere(
                      (doc) => doc.id == value,
                    );
                    final data = selectedDoc.data() as Map<String, dynamic>;

                    setState(() {
                      selectedWashId = value;
                      selectedWashName =
                          data['washName']?.toString() ??
                          data['name']?.toString() ??
                          'مغسلة بدون اسم';
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 12),

            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'عنوان الإعلان',
                hintText: 'مثال: خصم 30% على الغسيل الخارجي',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: bodyController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'نص الإعلان',
                hintText: 'اكتب تفاصيل العرض الذي سيظهر للعملاء',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: paidAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ المدفوع للإعلان',
                hintText: 'مثال: 150',
                border: OutlineInputBorder(),
                suffixText: 'ريال',
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: target,
              decoration: const InputDecoration(
                labelText: 'الفئة التي سيظهر لها الإعلان',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'customers', child: Text('العملاء')),
                DropdownMenuItem(value: 'all', child: Text('الكل')),
              ],
              onChanged: (value) {
                setState(() {
                  target = value ?? 'customers';
                });
              },
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : addPaidAd,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('إضافة الإعلان المدفوع'),
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

                    final isActive = data['isActive'] == true;
                    final type = data['type']?.toString() ?? 'general';
                    final paidAmount = data['paidAmount'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(
                                data['title'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${data['body'] ?? ''}\n'
                                'النوع: ${typeText(type)}\n'
                                'المغسلة: ${data['washName'] ?? '-'}\n'
                                'الفئة: ${targetText(data['target'] ?? 'all')}\n'
                                'المبلغ: $paidAmount ريال\n'
                                'الحالة: ${isActive ? 'فعال' : 'غير فعال'}',
                              ),
                              isThreeLine: true,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: SwitchListTile(
                                    title: Text(isActive ? 'فعال' : 'غير فعال'),
                                    value: isActive,
                                    onChanged: (_) {
                                      toggleNotification(doc.id, isActive);
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => deleteNotification(doc.id),
                                ),
                              ],
                            ),
                          ],
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
