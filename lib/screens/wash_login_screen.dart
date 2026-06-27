import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/session_service.dart';
import '../services/push_notification_service.dart';
import 'wash_register_screen.dart';
import 'wash_home_screen.dart';
import 'admin_screen.dart';

class WashLoginScreen extends StatefulWidget {
  const WashLoginScreen({super.key});

  @override
  State<WashLoginScreen> createState() => _WashLoginScreenState();
}

class _WashLoginScreenState extends State<WashLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> loginWash() async {
    try {
      setState(() {
        isLoading = true;
      });

      UserCredential credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final uid = credential.user!.uid;

      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();

      if (adminDoc.exists) {
        await PushNotificationService.registerDevice(
          userId: uid,
          userType: 'admin',
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminScreen()),
        );

        return;
      }

      final washDoc = await FirebaseFirestore.instance
          .collection('washes')
          .doc(uid)
          .get();

      if (!washDoc.exists) {
        throw Exception('المغسلة غير موجودة');
      }

      final data = washDoc.data()!;

      if (data['status'] != 'approved') {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حسابك قيد المراجعة من الإدارة')),
        );

        await FirebaseAuth.instance.signOut();
        return;
      }

      SessionService.currentWashId = uid;
      SessionService.currentWashName = data['washName'];

      await PushNotificationService.registerDevice(
        userId: uid,
        userType: 'wash',
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WashHomeScreen()),
      );
    } on FirebaseAuthException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('البريد الإلكتروني أو كلمة المرور غير صحيحة'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تسجيل دخول صاحب المغسلة'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 30),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : loginWash,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'تسجيل الدخول',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),

              const SizedBox(height: 15),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WashRegisterScreen(),
                    ),
                  );
                },
                child: const Text('ليس لديك حساب؟ تسجيل مغسلة جديدة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
