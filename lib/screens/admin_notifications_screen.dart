import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/ads_service.dart';

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

  DateTime? startAt;
  DateTime? endAt;

  bool isLoading = false;

  Future<void> pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: startAt ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (date == null) return;

    setState(() {
      startAt = DateTime(date.year, date.month, date.day);
      if (endAt != null && endAt!.isBefore(startAt!)) {
        endAt = null;
      }
    });
  }

  Future<void> pickEndDate() async {
    final initial = endAt ?? startAt ?? DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: startAt ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (date == null) return;

    setState(() {
      endAt = DateTime(date.year, date.month, date.day, 23, 59, 59);
    });
  }

  Future<void> addPaidAd() async {
    if (titleController.text.trim().isEmpty ||
        bodyController.text.trim().isEmpty ||
        selectedWashId.isEmpty ||
        paidAmountController.text.trim().isEmpty ||
        startAt == null ||
        endAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى تعبئة العنوان والنص واختيار المغسلة والمبلغ وتاريخ البداية والنهاية',
          ),
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

    if (endAt!.isBefore(startAt!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تاريخ النهاية يجب أن يكون بعد البداية')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await AdsService.addPaidAd(
        title: titleController.text,
        body: bodyController.text,
        target: target,
        washId: selectedWashId,
        washName: selectedWashName,
        paidAmount: paidAmount,
        startAt: startAt!,
        endAt: endAt!,
      );

      titleController.clear();
      bodyController.clear();
      paidAmountController.clear();

      setState(() {
        target = 'customers';
        selectedWashId = '';
        selectedWashName = '';
        startAt = null;
        endAt = null;
        isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة الإعلان المدفوع بنجاح')),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
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

  String formatLocalDate(DateTime? date) {
    if (date == null) return 'اختر التاريخ';
    return '${date.day}/${date.month}/${date.year}';
  }

  Color statusColor(String status) {
    if (status == 'فعال') return Colors.green;
    if (status == 'لم يبدأ') return Colors.orange;
    if (status == 'منتهي') return Colors.red;
    return Colors.grey;
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    paidAmountController.dispose();
    super.dispose();
  }

  Widget dateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.date_range),
      label: Text('$label: ${formatLocalDate(date)}'),
    );
  }

  Widget adStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
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
                  initialValue: selectedWashId.isEmpty ? null : selectedWashId,
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

            Row(
              children: [
                Expanded(
                  child: dateButton(
                    label: 'تاريخ البداية',
                    date: startAt,
                    onPressed: pickStartDate,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: dateButton(
                    label: 'تاريخ النهاية',
                    date: endAt,
                    onPressed: pickEndDate,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: target,
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

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('type', isEqualTo: 'paid_ad')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('لا توجد إعلانات حالياً'));
                }

                final notifications = snapshot.data!.docs;

                return Column(
                  children: notifications.map((doc) {
                    final data = doc.data();

                    final isActive = data['isActive'] == true;
                    final type = data['type']?.toString() ?? 'general';
                    final paidAmount = AdsService.paidAmount(data);
                    final status = AdsService.adStatusText(data);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            ListTile(
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      data['title']?.toString() ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  adStatusBadge(status),
                                ],
                              ),
                              subtitle: Text(
                                '${data['body']?.toString() ?? ''}\n'
                                'النوع: ${typeText(type)}\n'
                                'المغسلة: ${data['washName']?.toString() ?? '-'}\n'
                                'الفئة: ${targetText(data['target']?.toString() ?? 'all')}\n'
                                'المبلغ: $paidAmount ريال\n'
                                'تاريخ البداية: ${AdsService.formatDate(data['startAt'])}\n'
                                'تاريخ النهاية: ${AdsService.formatDate(data['endAt'])}\n'
                                'الحالة: $status',
                              ),
                              isThreeLine: false,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: SwitchListTile(
                                    title: Text(isActive ? 'فعال' : 'غير فعال'),
                                    value: isActive,
                                    onChanged: (_) {
                                      AdsService.toggleAdStatus(
                                        adId: doc.id,
                                        currentValue: isActive,
                                      );
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    AdsService.deleteAd(doc.id);
                                  },
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
