import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'screens/customer_register_screen.dart';
import 'screens/wash_register_screen.dart';
import 'screens/customer_login_screen.dart';
import 'screens/wash_login_screen.dart';

import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MawedGhaseelApp());
}

class MawedGhaseelApp extends StatelessWidget {
  const MawedGhaseelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'موعد غسيل',
      theme: AppTheme.lightTheme,
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void copyText(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void showSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Icon(Icons.headset_mic, color: AppColors.primary, size: 30),
                    SizedBox(width: 10),
                    Text(
                      'الشكاوى والاقتراحات',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'نرحب بجميع ملاحظاتكم واقتراحاتكم لتحسين الخدمة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 18),
                supportItem(
                  context: context,
                  title: 'البريد الإلكتروني',
                  value: 'sale7-9999@hotmail.com',
                  icon: Icons.email_outlined,
                  onCopy: () => copyText(
                    context,
                    'sale7-9999@hotmail.com',
                    'تم نسخ البريد الإلكتروني',
                  ),
                ),
                const SizedBox(height: 12),
                supportItem(
                  context: context,
                  title: 'رقم الجوال',
                  value: '0532 299 990',
                  icon: Icons.phone,
                  onCopy: () =>
                      copyText(context, '0532299990', 'تم نسخ رقم الجوال'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'سنقوم بالرد عليكم في أقرب وقت ممكن.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إغلاق'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget supportItem({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.10),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget buildLogo() {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.directions_car_filled,
            size: 52,
            color: AppColors.primaryDark,
          ),
          Positioned(
            top: 24,
            right: 28,
            child: Icon(
              Icons.water_drop,
              color: AppColors.primary.withOpacity(0.9),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget featureCard(IconData icon, String title) {
    return Expanded(
      child: Container(
        height: 82,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.75)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primaryDark, size: 28),
            const SizedBox(height: 7),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget mainButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
      ),
    );
  }

  Widget outlineButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
      ),
    );
  }

  Widget glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.75)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/welcome_background.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.white.withOpacity(0.10)),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.92),
                          child: IconButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('لا توجد إشعارات حالياً'),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.notifications,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Column(
                              children: [
                                buildLogo(),
                                const SizedBox(height: 16),
                                const Text(
                                  'موعد غسيل',
                                  style: TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primaryDark,
                                    shadows: [
                                      Shadow(
                                        color: Colors.white,
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'احجز غسيل سيارتك بسهولة',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Row(
                                  children: [
                                    featureCard(
                                      Icons.verified_user,
                                      'مغاسل معتمدة',
                                    ),
                                    const SizedBox(width: 10),
                                    featureCard(Icons.timer, 'حجز سريع'),
                                    const SizedBox(width: 10),
                                    featureCard(
                                      Icons.calendar_month,
                                      'مواعيد دقيقة',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                glassCard(
                                  child: Column(
                                    children: [
                                      sectionTitle(
                                        'تسجيل الدخول',
                                        Icons.account_circle,
                                      ),
                                      const SizedBox(height: 14),
                                      mainButton(
                                        'دخول العميل',
                                        Icons.person,
                                        () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const CustomerLoginScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      mainButton(
                                        'دخول صاحب المغسلة',
                                        Icons.store,
                                        () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const WashLoginScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 22),
                                      const Divider(),
                                      const SizedBox(height: 12),
                                      sectionTitle(
                                        'إنشاء حساب جديد',
                                        Icons.person_add_alt_1,
                                      ),
                                      const SizedBox(height: 14),
                                      outlineButton(
                                        'عميل جديد',
                                        Icons.person_add,
                                        () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const CustomerRegisterScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      outlineButton(
                                        'تسجيل مغسلة جديدة',
                                        Icons.add_business,
                                        () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const WashRegisterScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.82),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => showSupportSheet(context),
                            icon: const Icon(Icons.headset_mic),
                            label: const Text('الشكاوى والاقتراحات'),
                          ),
                          const Spacer(),
                          const Text(
                            'منصة مخصصة لتنظيم حجوزات\nمغاسل السيارات',
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
