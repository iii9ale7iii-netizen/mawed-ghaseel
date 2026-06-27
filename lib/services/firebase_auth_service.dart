import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String?> registerCustomer({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('customers').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'createdAt': Timestamp.now(),
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<String?> loginCustomer({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;

      if (uid == null) {
        await _auth.signOut();
        return 'تعذر قراءة بيانات الحساب';
      }

      final customerDoc = await _firestore.collection('customers').doc(uid).get();

      if (!customerDoc.exists) {
        await _auth.signOut();
        return 'هذا الحساب غير مسجل كعميل. استخدم دخول صاحب المغسلة.';
      }

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
