import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../services/working_hours_service.dart';
import '../theme/app_glass_ui.dart';
import 'service_selection_screen.dart';

class WashListScreen extends StatefulWidget {
  const WashListScreen({super.key});

  @override
  State<WashListScreen> createState() => _WashListScreenState();
}

class _WashListScreenState extends State<WashListScreen> {
  Position? customerPosition;
  bool isLocating = false;
  String? locationMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      locateCustomer();
    });
  }

  Future<void> locateCustomer() async {
    if (isLocating) return;

    try {
      setState(() {
        isLocating = true;
        locationMessage = null;
      });

      final position = await AppLocationService.currentPosition();

      if (!mounted) return;

      setState(() {
        customerPosition = position;
        locationMessage = 'تم تحديد موقعك وترتيب المغاسل حسب الأقرب.';
      });
    } on AppLocationException catch (error) {
      if (!mounted) return;
      setState(() {
        locationMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        locationMessage = 'تعذر تحديد موقعك. حاول مرة أخرى.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLocating = false;
        });
      }
    }
  }

  Color washStatusColor(String statusText) {
    if (statusText.contains('مفتوحة')) {
      return Colors.green;
    }

    if (statusText.contains('تفتح')) {
      return Colors.orange;
    }

    return Colors.red;
  }

  Widget washCard(
    BuildContext context,
    QueryDocumentSnapshot wash,
    Map<String, dynamic> data,
    double? distanceKm,
  ) {
    final washName =
        data['washName']?.toString() ?? data['name']?.toString() ?? 'مغسلة';
    final statusText = WorkingHoursService.washStatusText(data);
    final canBook = WorkingHoursService.isOpenAt(
      washData: data,
      dateTime: DateTime.now(),
    );
    final bookingEnabled = WorkingHoursService.isWashBookingEnabled(data);
    final statusColor = !bookingEnabled
        ? Colors.red
        : canBook
            ? Colors.green
            : washStatusColor(statusText);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppGlassCard(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppActionIcon(icon: Icons.local_car_wash_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        washName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppGlassUi.darkText,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      AppInfoRow(
                        icon: Icons.location_city_rounded,
                        text:
                            "${data['city']?.toString() ?? ''} - ${data['washType']?.toString() ?? ''}",
                      ),
                      AppInfoRow(
                        icon: Icons.near_me_rounded,
                        text: AppLocationService.distanceLabel(distanceKm),
                        color: distanceKm == null
                            ? AppGlassUi.mutedText
                            : AppGlassUi.primary,
                      ),
                      AppInfoRow(
                        icon: Icons.schedule_rounded,
                        text: statusText,
                        color: statusColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AppGradientButton(
              title: 'اختيار',
              icon: Icons.arrow_back_rounded,
              onTap: canBook
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceSelectionScreen(
                            washId: wash.id,
                            washName: washName,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget nearbyMap(List<QueryDocumentSnapshot> washes) {
    final userLat = customerPosition?.latitude;
    final userLng = customerPosition?.longitude;
    final washPoints = <MapEntry<QueryDocumentSnapshot, LatLng>>[];

    for (final wash in washes) {
      final data = wash.data() as Map<String, dynamic>;
      final latitude = AppLocationService.readLatitude(data);
      final longitude = AppLocationService.readLongitude(data);

      if (latitude != null && longitude != null) {
        washPoints.add(MapEntry(wash, LatLng(latitude, longitude)));
      }
    }

    final center = userLat != null && userLng != null
        ? LatLng(userLat, userLng)
        : washPoints.isNotEmpty
            ? washPoints.first.value
            : const LatLng(24.7136, 46.6753);

    return AppGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 220,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: userLat == null ? 11 : 13,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.drag |
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.doubleTapZoom,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.mawedghaseel.lamah',
                  ),
                  MarkerLayer(
                    markers: [
                      if (userLat != null && userLng != null)
                        Marker(
                          point: LatLng(userLat, userLng),
                          width: 52,
                          height: 52,
                          child: const Icon(
                            Icons.person_pin_circle_rounded,
                            color: Color(0xFF16A34A),
                            size: 44,
                          ),
                        ),
                      ...washPoints.map(
                        (entry) => Marker(
                          point: entry.value,
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.local_car_wash_rounded,
                            color: AppGlassUi.primary,
                            size: 36,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppGradientButton(
            title: isLocating ? 'جاري تحديد الموقع...' : 'تحديد موقعي',
            icon: Icons.my_location_rounded,
            onTap: isLocating ? null : locateCustomer,
          ),
          if (locationMessage != null) ...[
            const SizedBox(height: 10),
            AppInfoRow(
              icon: Icons.info_outline_rounded,
              text: locationMessage!,
              color: customerPosition == null ? Colors.orange : Colors.green,
            ),
          ],
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('washes')
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, washesSnapshot) {
        if (washesSnapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingState();
        }

        if (washesSnapshot.hasError) {
          return AppEmptyState(
            title: 'خطأ في تحميل المغاسل: ${washesSnapshot.error}',
            icon: Icons.error_outline_rounded,
          );
        }

        if (!washesSnapshot.hasData || washesSnapshot.data!.docs.isEmpty) {
          return const AppEmptyState(
            title: 'لا توجد مغاسل متاحة حالياً',
            icon: Icons.local_car_wash_outlined,
          );
        }

        final washes = [...washesSnapshot.data!.docs];
        final userLat = customerPosition?.latitude;
        final userLng = customerPosition?.longitude;

        washes.sort((first, second) {
          final firstDistance = AppLocationService.distanceKm(
            fromLatitude: userLat,
            fromLongitude: userLng,
            washData: first.data() as Map<String, dynamic>,
          );
          final secondDistance = AppLocationService.distanceKm(
            fromLatitude: userLat,
            fromLongitude: userLng,
            washData: second.data() as Map<String, dynamic>,
          );

          if (firstDistance == null && secondDistance == null) return 0;
          if (firstDistance == null) return 1;
          if (secondDistance == null) return -1;
          return firstDistance.compareTo(secondDistance);
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppSectionTitle(
              title: 'المغاسل المتاحة',
              subtitle: 'اختر المغسلة المناسبة واحجز خدمتك',
              icon: Icons.local_car_wash_rounded,
            ),
            const SizedBox(height: 14),
            nearbyMap(washes),
            const SizedBox(height: 16),
            ...washes.map((wash) {
              final data = wash.data() as Map<String, dynamic>;
              final distanceKm = AppLocationService.distanceKm(
                fromLatitude: userLat,
                fromLongitude: userLng,
                washData: data,
              );

              return washCard(context, wash, data, distanceKm);
            }),
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
            AppGlassTopBar(
              title: 'اختر المغسلة',
              leadingIcon: Icons.arrow_back_rounded,
              leadingTooltip: 'رجوع',
            ),
            const SizedBox(height: 18),
            _content(context),
          ],
        ),
      ),
    );
  }
}
