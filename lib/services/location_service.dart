import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

class AppLocationException implements Exception {
  final String message;

  const AppLocationException(this.message);

  @override
  String toString() => message;
}

class AppLocationService {
  AppLocationService._();

  static Future<Position> currentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw const AppLocationException('فعل خدمة الموقع من إعدادات الجهاز.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const AppLocationException('اسمح للتطبيق باستخدام موقعك لعرض الأقرب.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const AppLocationException(
        'إذن الموقع مرفوض نهائيا. افتح إعدادات التطبيق وفعله.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  static double? readLatitude(Map<String, dynamic> data) {
    return _readDouble(data['latitude'] ?? data['lat']);
  }

  static double? readLongitude(Map<String, dynamic> data) {
    return _readDouble(data['longitude'] ?? data['lng']);
  }

  static bool hasCoordinates(Map<String, dynamic> data) {
    return readLatitude(data) != null && readLongitude(data) != null;
  }

  static double? distanceKm({
    required double? fromLatitude,
    required double? fromLongitude,
    required Map<String, dynamic> washData,
  }) {
    final toLatitude = readLatitude(washData);
    final toLongitude = readLongitude(washData);

    if (fromLatitude == null ||
        fromLongitude == null ||
        toLatitude == null ||
        toLongitude == null) {
      return null;
    }

    return _haversineKm(
      fromLatitude,
      fromLongitude,
      toLatitude,
      toLongitude,
    );
  }

  static String distanceLabel(double? distanceKm) {
    if (distanceKm == null) return 'المسافة غير محددة';
    if (distanceKm < 1) return '${(distanceKm * 1000).round()} م';
    return '${distanceKm.toStringAsFixed(distanceKm < 10 ? 1 : 0)} كم';
  }

  static double? _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static double _haversineKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const radiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return radiusKm * c;
  }

  static double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }
}
