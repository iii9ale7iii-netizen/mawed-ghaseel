import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initialize() async {
    if (kIsWeb) return;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
  }

  static Future<void> registerDevice({
    required String userId,
    required String userType,
  }) async {
    if (kIsWeb) return;
    if (userId.isEmpty) return;

    await initialize();

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _saveToken(userId: userId, userType: userType, token: token);

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _saveToken(userId: userId, userType: userType, token: newToken);
    });
  }

  static Future<void> _saveToken({
    required String userId,
    required String userType,
    required String token,
  }) async {
    final tokenId = '${userId}_${token.hashCode}';

    await _firestore.collection('fcm_tokens').doc(tokenId).set({
      'userId': userId,
      'userType': userType,
      'token': token,
      'platform': defaultTargetPlatform.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
