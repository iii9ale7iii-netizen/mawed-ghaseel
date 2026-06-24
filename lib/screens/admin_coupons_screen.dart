import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  final codeController = TextEditingController();
  final discountController = TextEditingController();

  bool isLoading = false;

  Future<void> addCoupon() async {
    if (codeController.text.isEmpty || discountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال كود الخصم ونسبة الخصم')),
      );
      return;
    }

    final discount = int.tryParse(discountController.text);

    if (discount == null || discount <= 0 || discount > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نسبة الخصم يجب أن تكون بين 1 و 100')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    await FirebaseFirestore.instance.collection('coupons').add({
      'code': codeController.text.trim().toUpperCase(),
      'discount': discount,
      'isActive': true,
      'createdAt': Timestamp.now(),
    });

    codeController.clear();
    discountController.clear();

    setState(() {
      isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إضافة كود الخصم بنجاح')));
    }
  }

  Future<void> toggleCoupon(String id, bool currentValue) async {
    await FirebaseFirestore.instance.collection('coupons').doc(id).update({
      'isActive': !currentValue,
    });
  }

  Future<void> deleteCoupon(String id) async {
    await FirebaseFirestore.instance.collection('coupons').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة أكواد الخصم'),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'كود الخصم',
                hintText: 'مثال: WASH20',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: discountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'نسبة الخصم',
                hintText: 'مثال: 20',
                border: OutlineInputBorder(),
                suffixText: '%',
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : addCoupon,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text('إضافة كود الخصم'),
              ),
            ),
            const Divider(height: 35),
            const Text(
              'أكواد الخصم الحالية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('coupons')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('لا توجد أكواد خصم حالياً'));
                }

                final coupons = snapshot.data!.docs;

                return Column(
                  children: coupons.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final isActive = data['isActive'] ?? true;

                    return Card(
                      child: ListTile(
                        title: Text(
                          data['code'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'الخصم: ${data['discount'] ?? 0}%\nالحالة: ${isActive ? 'فعال' : 'غير فعال'}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: isActive,
                              onChanged: (_) => toggleCoupon(doc.id, isActive),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteCoupon(doc.id),
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
