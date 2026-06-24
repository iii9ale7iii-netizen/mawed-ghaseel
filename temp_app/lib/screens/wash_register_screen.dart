import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WashRegisterScreen extends StatefulWidget {
  const WashRegisterScreen({super.key});

  @override
  State<WashRegisterScreen> createState() => _WashRegisterScreenState();
}

class _WashRegisterScreenState extends State<WashRegisterScreen> {
  final TextEditingController washNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String? washType = 'ثابتة';

  bool isLoading = false;

  Future<void> registerWash() async {
    if (washNameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty ||
        districtController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('يرجى تعبئة جميع الحقول')));
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('كلمتا المرور غير متطابقتين')),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection('washes')
          .doc(credential.user!.uid)
          .set({
            'uid': credential.user!.uid,
            'washName': washNameController.text.trim(),
            'washType': washType,
            'phone': phoneController.text.trim(),
            'city': cityController.text.trim(),
            'district': districtController.text.trim(),
            'email': emailController.text.trim(),
            'status': 'pending',
            'createdAt': Timestamp.now(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال طلب التسجيل وحسابك قيد المراجعة'),
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ';

      if (e.code == 'email-already-in-use') {
        message = 'البريد الإلكتروني مستخدم مسبقاً';
      } else if (e.code == 'weak-password') {
        message = 'كلمة المرور ضعيفة';
      } else if (e.code == 'invalid-email') {
        message = 'البريد الإلكتروني غير صحيح';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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
          title: const Text('تسجيل مغسلة جديدة'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: washNameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المغسلة',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                initialValue: washType,
                decoration: const InputDecoration(
                  labelText: 'نوع المغسلة',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ثابتة', child: Text('ثابتة')),
                  DropdownMenuItem(value: 'متنقلة', child: Text('متنقلة')),
                ],
                onChanged: (value) {
                  setState(() {
                    washType = value;
                  });
                },
              ),

              const SizedBox(height: 15),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الجوال',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: cityController,
                decoration: const InputDecoration(
                  labelText: 'المدينة',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: districtController,
                decoration: const InputDecoration(
                  labelText: 'الحي',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

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

              const SizedBox(height: 15),

              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : registerWash,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'إرسال طلب التسجيل',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
