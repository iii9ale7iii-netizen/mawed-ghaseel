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
                  color: Colors.black.withValues(alpha: 0.15),
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
                    Icon(
                      Icons.support_agent_rounded,
                      color: AppColors.primary,
                      size: 30,
                    ),
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
            backgroundColor: AppColors.primary.withValues(alpha: 0.10),
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
      width: 108,
      height: 108,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD8ECFF), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/logo_mawed_ghaseel.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.local_car_wash_rounded,
            color: AppColors.primaryDark,
            size: 56,
          );
        },
      ),
    );
  }

  Widget featureCard(IconData icon, String title) {
    return Expanded(
      child: Container(
        height: 88,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryDark, size: 25),
            const SizedBox(height: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.primary, size: 26),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontSize: 21,
            fontWeight: FontWeight.w900,
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
        icon: Icon(icon, size: 22),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          elevation: 7,
          shadowColor: AppColors.primaryDark.withValues(alpha: 0.25),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget outlineButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: Colors.white.withValues(alpha: 0.72),
          side: const BorderSide(color: AppColors.primary, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.91),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.76)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => showSupportSheet(context),
            icon: const Icon(Icons.support_agent_rounded, size: 20),
            label: const Text(
              'الشكاوى والاقتراحات',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 32, color: AppColors.border),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'منصة مخصصة لتنظيم حجوزات مغاسل السيارات',
              textAlign: TextAlign.start,
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWelcomeContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('لا توجد إشعارات حالياً')),
                  );
                },
                icon: const Icon(
                  Icons.notifications_rounded,
                  color: AppColors.primaryDark,
                  size: 23,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          buildLogo(),
          const SizedBox(height: 15),
          const Text(
            'موعد غسيل',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryDark,
              shadows: [Shadow(color: Colors.white, blurRadius: 12)],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'اغسل سيارتك في دقائق',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              shadows: [Shadow(color: Colors.white, blurRadius: 8)],
            ),
          ),
          const SizedBox(height: 21),
          Row(
            children: [
              featureCard(Icons.verified_user, 'مغاسل معتمدة'),
              const SizedBox(width: 10),
              featureCard(Icons.timer, 'حجز سريع'),
              const SizedBox(width: 10),
              featureCard(Icons.calendar_month, 'مواعيد دقيقة'),
            ],
          ),
          const SizedBox(height: 21),
          glassCard(
            child: Column(
              children: [
                sectionTitle('تسجيل الدخول', Icons.account_circle),
                const SizedBox(height: 16),
                mainButton('دخول العميل', Icons.person, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomerLoginScreen(),
                    ),
                  );
                }),
                const SizedBox(height: 11),
                mainButton('دخول صاحب المغسلة', Icons.store, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WashLoginScreen()),
                  );
                }),
                const SizedBox(height: 17),
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'أو',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 17),
                outlineButton('إنشاء حساب عميل جديد', Icons.person_add, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomerRegisterScreen(),
                    ),
                  );
                }),
                const SizedBox(height: 11),
                outlineButton('تسجيل مغسلة جديدة', Icons.add_business, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WashRegisterScreen(),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),
          buildFooter(context),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFEAF5FF),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final double frameWidth = constraints.maxWidth > 460
                ? 430
                : constraints.maxWidth;

            return Center(
              child: SizedBox(
                width: frameWidth,
                height: constraints.maxHeight,
                child: ClipRRect(
                  borderRadius: constraints.maxWidth > 460
                      ? BorderRadius.circular(28)
                      : BorderRadius.zero,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/welcome_background.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.bottomRight,
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.72),
                                Colors.white.withValues(alpha: 0.46),
                                Colors.white.withValues(alpha: 0.20),
                                Colors.white.withValues(alpha: 0.06),
                              ],
                              stops: const [0.0, 0.38, 0.72, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.18),
                                Colors.white.withValues(alpha: 0.03),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: ScrollConfiguration(
                          behavior: const _NoGlowScrollBehavior(),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              child: buildWelcomeContent(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
