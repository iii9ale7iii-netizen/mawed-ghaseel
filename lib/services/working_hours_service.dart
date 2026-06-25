import 'package:cloud_firestore/cloud_firestore.dart';

class WorkingHoursService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final Map<String, String> arabicDayNames = {
    'saturday': 'السبت',
    'sunday': 'الأحد',
    'monday': 'الاثنين',
    'tuesday': 'الثلاثاء',
    'wednesday': 'الأربعاء',
    'thursday': 'الخميس',
    'friday': 'الجمعة',
  };

  static final Map<String, String> defaultWorkingHours = {
    'saturday_enabled': 'true',
    'saturday_from': '08:00',
    'saturday_to': '23:00',
    'sunday_enabled': 'true',
    'sunday_from': '08:00',
    'sunday_to': '23:00',
    'monday_enabled': 'true',
    'monday_from': '08:00',
    'monday_to': '23:00',
    'tuesday_enabled': 'true',
    'tuesday_from': '08:00',
    'tuesday_to': '23:00',
    'wednesday_enabled': 'true',
    'wednesday_from': '08:00',
    'wednesday_to': '23:00',
    'thursday_enabled': 'true',
    'thursday_from': '08:00',
    'thursday_to': '23:00',
    'friday_enabled': 'false',
    'friday_from': '00:00',
    'friday_to': '00:00',
  };

  static Map<String, dynamic> defaultWorkingHoursMap() {
    return {
      'saturday': {'enabled': true, 'from': '08:00', 'to': '23:00'},
      'sunday': {'enabled': true, 'from': '08:00', 'to': '23:00'},
      'monday': {'enabled': true, 'from': '08:00', 'to': '23:00'},
      'tuesday': {'enabled': true, 'from': '08:00', 'to': '23:00'},
      'wednesday': {'enabled': true, 'from': '08:00', 'to': '23:00'},
      'thursday': {'enabled': true, 'from': '08:00', 'to': '23:00'},
      'friday': {'enabled': false, 'from': '00:00', 'to': '00:00'},
    };
  }

  static Future<void> initializeWashWorkingHoursIfMissing(String washId) async {
    if (washId.isEmpty) return;

    final doc = await _firestore.collection('washes').doc(washId).get();

    if (!doc.exists) return;

    final data = doc.data() ?? {};

    final updates = <String, dynamic>{};

    if (!data.containsKey('bookingEnabled')) {
      updates['bookingEnabled'] = true;
    }

    if (!data.containsKey('workingHours')) {
      updates['workingHours'] = defaultWorkingHoursMap();
    }

    if (updates.isNotEmpty) {
      await _firestore.collection('washes').doc(washId).update(updates);
    }
  }

  static Future<void> updateBookingEnabled({
    required String washId,
    required bool enabled,
  }) async {
    if (washId.isEmpty) return;

    await _firestore.collection('washes').doc(washId).update({
      'bookingEnabled': enabled,
      'updatedAt': Timestamp.now(),
    });
  }

  static Future<void> updateWorkingHours({
    required String washId,
    required Map<String, dynamic> workingHours,
  }) async {
    if (washId.isEmpty) return;

    await _firestore.collection('washes').doc(washId).update({
      'workingHours': workingHours,
      'updatedAt': Timestamp.now(),
    });
  }

  static String dayKeyFromDate(DateTime date) {
    switch (date.weekday) {
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
        return 'sunday';
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      default:
        return 'saturday';
    }
  }

  static String arabicDayName(String dayKey) {
    return arabicDayNames[dayKey] ?? dayKey;
  }

  static int timeToMinutes(String time) {
    final parts = time.split(':');

    if (parts.length != 2) return 0;

    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;

    return hour * 60 + minute;
  }

  static bool isWashBookingEnabled(Map<String, dynamic> washData) {
    if (!washData.containsKey('bookingEnabled')) return true;
    return washData['bookingEnabled'] == true;
  }

  static Map<String, dynamic> getWorkingHours(Map<String, dynamic> washData) {
    final value = washData['workingHours'];

    if (value is Map<String, dynamic>) {
      return value;
    }

    return defaultWorkingHoursMap();
  }

  static bool isOpenAt({
    required Map<String, dynamic> washData,
    required DateTime dateTime,
  }) {
    if (!isWashBookingEnabled(washData)) return false;

    final workingHours = getWorkingHours(washData);
    final dayKey = dayKeyFromDate(dateTime);
    final dayDataRaw = workingHours[dayKey];

    if (dayDataRaw is! Map) return false;

    final dayData = Map<String, dynamic>.from(dayDataRaw);
    final enabled = dayData['enabled'] == true;

    if (!enabled) return false;

    final from = dayData['from']?.toString() ?? '00:00';
    final to = dayData['to']?.toString() ?? '00:00';

    final currentMinutes = dateTime.hour * 60 + dateTime.minute;
    final fromMinutes = timeToMinutes(from);
    final toMinutes = timeToMinutes(to);

    return currentMinutes >= fromMinutes && currentMinutes <= toMinutes;
  }

  static String washStatusText(Map<String, dynamic> washData) {
    if (!isWashBookingEnabled(washData)) {
      return 'لا تستقبل حجوزات حالياً';
    }

    final now = DateTime.now();
    final workingHours = getWorkingHours(washData);
    final dayKey = dayKeyFromDate(now);
    final dayDataRaw = workingHours[dayKey];

    if (dayDataRaw is! Map) return 'مغلقة حالياً';

    final dayData = Map<String, dynamic>.from(dayDataRaw);
    final enabled = dayData['enabled'] == true;

    if (!enabled) {
      return 'مغلقة اليوم';
    }

    final from = dayData['from']?.toString() ?? '00:00';
    final to = dayData['to']?.toString() ?? '00:00';

    if (isOpenAt(washData: washData, dateTime: now)) {
      return 'مفتوحة الآن حتى $to';
    }

    final currentMinutes = now.hour * 60 + now.minute;
    final fromMinutes = timeToMinutes(from);

    if (currentMinutes < fromMinutes) {
      return 'تفتح الساعة $from';
    }

    return 'مغلقة حالياً';
  }
}
