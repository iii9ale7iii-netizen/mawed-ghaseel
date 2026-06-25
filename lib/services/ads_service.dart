import 'package:cloud_firestore/cloud_firestore.dart';

class AdsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  static Future<void> addPaidAd({
    required String title,
    required String body,
    required String target,
    required String washId,
    required String washName,
    required double paidAmount,
    required DateTime startAt,
    required DateTime endAt,
  }) async {
    if (title.trim().isEmpty) {
      throw Exception('عنوان الإعلان مطلوب');
    }

    if (body.trim().isEmpty) {
      throw Exception('نص الإعلان مطلوب');
    }

    if (washId.trim().isEmpty) {
      throw Exception('يجب اختيار المغسلة');
    }

    if (paidAmount <= 0) {
      throw Exception('المبلغ المدفوع غير صحيح');
    }

    if (endAt.isBefore(startAt)) {
      throw Exception('تاريخ نهاية الإعلان يجب أن يكون بعد تاريخ البداية');
    }

    await _notifications.add({
      'title': title.trim(),
      'body': body.trim(),
      'target': target,
      'type': 'paid_ad',
      'washId': washId,
      'washName': washName,
      'paidAmount': paidAmount,
      'isActive': true,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'createdAt': Timestamp.now(),
    });
  }

  static Future<void> toggleAdStatus({
    required String adId,
    required bool currentValue,
  }) async {
    await _notifications.doc(adId).update({'isActive': !currentValue});
  }

  static Future<void> deleteAd(String adId) async {
    await _notifications.doc(adId).delete();
  }

  static bool isPaidAd(Map<String, dynamic> data) {
    return data['type']?.toString() == 'paid_ad';
  }

  static bool isActiveBySwitch(Map<String, dynamic> data) {
    return data['isActive'] == true;
  }

  static bool isVisibleToCustomers(Map<String, dynamic> data) {
    final target = data['target']?.toString() ?? 'customers';

    return target == 'customers' || target == 'all';
  }

  static bool hasStarted(Map<String, dynamic> data) {
    final startAt = data['startAt'];

    if (startAt is! Timestamp) {
      return true;
    }

    return !DateTime.now().isBefore(startAt.toDate());
  }

  static bool hasEnded(Map<String, dynamic> data) {
    final endAt = data['endAt'];

    if (endAt is! Timestamp) {
      return false;
    }

    return DateTime.now().isAfter(endAt.toDate());
  }

  static bool isCurrentlyActivePaidAd(Map<String, dynamic> data) {
    return isPaidAd(data) &&
        isActiveBySwitch(data) &&
        isVisibleToCustomers(data) &&
        hasStarted(data) &&
        !hasEnded(data);
  }

  static String adStatusText(Map<String, dynamic> data) {
    final isActive = data['isActive'] == true;

    if (!isActive) return 'غير فعال';

    if (!hasStarted(data)) return 'لم يبدأ';

    if (hasEnded(data)) return 'منتهي';

    return 'فعال';
  }

  static double paidAmount(Map<String, dynamic> data) {
    final value = data['paidAmount'];

    if (value is int) return value.toDouble();
    if (value is double) return value;

    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  static String formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    return '-';
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> adsStream() {
    return _notifications.orderBy('createdAt', descending: true).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> activePaidAdsStream() {
    return _notifications.snapshots();
  }
}
