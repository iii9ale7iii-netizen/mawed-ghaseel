import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/session_service.dart';
import '../theme/app_glass_ui.dart';

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
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    durationController.dispose();
    super.dispose();
  }

  Widget _serviceCard(QueryDocumentSnapshot service) {
    final data = service.data() as Map<String, dynamic>;
    final serviceName = data['serviceName']?.toString() ?? '';
    final price = data['price']?.toString() ?? '';
    final duration = data['durationMinutes']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppGlassCard(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            const AppActionIcon(icon: Icons.design_services_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppGlassUi.darkText,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  AppInfoRow(
                    icon: Icons.payments_rounded,
                    text: '$price ريال - $duration دقيقة',
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppCircleIconButton(
              icon: Icons.delete_rounded,
              tooltip: 'حذف الخدمة',
              onTap: () => deleteService(service.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _servicesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('services')
          .where('washId', isEqualTo: SessionService.currentWashId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AppLoadingState();
        }

        final services = snapshot.data!.docs;

        if (services.isEmpty) {
          return const AppEmptyState(
            title: 'لا توجد خدمات مضافة حالياً',
            icon: Icons.design_services_outlined,
          );
        }

        return Column(children: services.map(_serviceCard).toList());
      },
    );
  }

  Widget _addServiceForm() {
    return AppGlassCard(
      child: Column(
        children: [
          const AppSectionTitle(
            title: 'إضافة خدمة',
            subtitle: 'أدخل بيانات الخدمة كما ستظهر للعميل',
            icon: Icons.add_circle_rounded,
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: nameController,
            label: 'اسم الخدمة',
            icon: Icons.local_car_wash_rounded,
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: priceController,
            label: 'السعر',
            icon: Icons.payments_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: durationController,
            label: 'مدة الخدمة بالدقائق',
            icon: Icons.timer_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),
          AppGradientButton(
            title: 'إضافة خدمة',
            icon: Icons.add_rounded,
            onTap: addService,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppGlassScaffold(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppGlassTopBar(
              title: 'إدارة الخدمات',
              leadingIcon: Icons.arrow_back_rounded,
              leadingTooltip: 'رجوع',
            ),
            const SizedBox(height: 18),
            _addServiceForm(),
            const SizedBox(height: 18),
            const AppSectionTitle(
              title: 'الخدمات الحالية',
              subtitle: 'الخدمات المرتبطة بهذه المغسلة',
              icon: Icons.list_alt_rounded,
            ),
            const SizedBox(height: 12),
            _servicesList(),
          ],
        ),
      ),
    );
  }
}
