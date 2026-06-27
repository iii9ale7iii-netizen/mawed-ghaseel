import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../services/session_service.dart';
import '../theme/app_glass_ui.dart';

class WashLocationScreen extends StatefulWidget {
  const WashLocationScreen({super.key});

  @override
  State<WashLocationScreen> createState() => _WashLocationScreenState();
}

class _WashLocationScreenState extends State<WashLocationScreen> {
  bool isSaving = false;

  Future<void> saveCurrentLocation() async {
    final washId = SessionService.currentWashId ?? '';

    if (washId.isEmpty) {
      showMessage('لم يتم العثور على حساب المغسلة.');
      return;
    }

    try {
      setState(() {
        isSaving = true;
      });

      final position = await AppLocationService.currentPosition();

      await FirebaseFirestore.instance.collection('washes').doc(washId).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      showMessage('تم حفظ موقع المغسلة بنجاح.');
    } on AppLocationException catch (error) {
      if (!mounted) return;
      showMessage(error.message);
    } catch (error) {
      if (!mounted) return;
      showMessage('تعذر حفظ الموقع. حاول مرة أخرى.');
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget mapPreview(Map<String, dynamic> data) {
    final latitude = AppLocationService.readLatitude(data);
    final longitude = AppLocationService.readLongitude(data);

    if (latitude == null || longitude == null) {
      return AppGlassCard(
        child: Column(
          children: [
            const AppActionIcon(icon: Icons.location_off_rounded, active: false),
            const SizedBox(height: 12),
            const Text(
              'لم يتم حفظ موقع المغسلة بعد',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppGlassUi.darkText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'احفظ الموقع من داخل المغسلة أو من أقرب نقطة للعميل.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppGlassUi.mutedText,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    final center = LatLng(latitude, longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 260,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.drag |
                  InteractiveFlag.pinchZoom |
                  InteractiveFlag.doubleTapZoom,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.mawedghaseel.lamah',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 54,
                  height: 54,
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppGlassUi.primary,
                    size: 46,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget content() {
    final washId = SessionService.currentWashId ?? '';

    if (washId.isEmpty) {
      return const AppEmptyState(
        title: 'سجل الدخول بحساب المغسلة أولا.',
        icon: Icons.lock_outline_rounded,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream:
          FirebaseFirestore.instance.collection('washes').doc(washId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingState();
        }

        final data = snapshot.data?.data() ?? {};
        final hasLocation = AppLocationService.hasCoordinates(data);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionTitle(
              title: 'موقع المغسلة',
              subtitle: 'احفظ موقعك ليظهر للعملاء القريبين منك.',
              icon: Icons.map_rounded,
            ),
            const SizedBox(height: 14),
            mapPreview(data),
            const SizedBox(height: 14),
            AppGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppInfoRow(
                    icon: hasLocation
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    text: hasLocation
                        ? 'الموقع محفوظ وسيظهر في قائمة المغاسل القريبة.'
                        : 'لم يتم تحديد الموقع بعد.',
                    color: hasLocation ? Colors.green : Colors.orange,
                  ),
                  if (data['locationUpdatedAt'] is Timestamp) ...[
                    const SizedBox(height: 6),
                    AppInfoRow(
                      icon: Icons.update_rounded,
                      text:
                          'آخر تحديث: ${(data['locationUpdatedAt'] as Timestamp).toDate()}',
                    ),
                  ],
                  const SizedBox(height: 14),
                  AppGradientButton(
                    title: isSaving ? 'جاري الحفظ...' : 'حفظ موقعي الحالي',
                    icon: Icons.my_location_rounded,
                    onTap: isSaving ? null : saveCurrentLocation,
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
            const AppGlassTopBar(
              title: 'موقع المغسلة',
              leadingIcon: Icons.arrow_back_rounded,
              leadingTooltip: 'رجوع',
            ),
            const SizedBox(height: 18),
            content(),
          ],
        ),
      ),
    );
  }
}
