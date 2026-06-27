import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/firebase_auth_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import 'customer_home_screen.dart';
import 'customer_register_screen.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  bool isLoading = false;
  bool isResettingPassword = false;
  bool obscurePassword = true;

  @override
  void initState() {
    super.initState();
    emailFocusNode.addListener(_refreshFocusState);
    passwordFocusNode.addListener(_refreshFocusState);
  }

  void _refreshFocusState() {
    if (mounted) setState(() {});
  }

  Future<void> login() async {
    if (isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    final result = await FirebaseAuthService.loginCustomer(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (result != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('بيانات الدخول غير صحيحة')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر قراءة بيانات الحساب')),
      );
      return;
    }

    final customerDoc = await FirebaseFirestore.instance
        .collection('customers')
        .doc(user.uid)
        .get();
    final customerData = customerDoc.data() ?? {};

    SessionService.currentCustomerId = user.uid;
    SessionService.currentCustomerName =
        customerData['fullName']?.toString() ?? '';

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
    );
  }

  void _showForgotPasswordMessage() {
    _sendPasswordResetEmail();
  }

  Future<void> _sendPasswordResetEmail() async {
    if (isResettingPassword || isLoading) return;

    FocusScope.of(context).unfocus();

    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اكتب البريد الإلكتروني أولاً لاستعادة كلمة المرور'),
        ),
      );
      emailFocusNode.requestFocus();
      return;
    }

    final emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegExp.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('صيغة البريد الإلكتروني غير صحيحة')),
      );
      emailFocusNode.requestFocus();
      return;
    }

    setState(() {
      isResettingPassword = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إرسال رابط استعادة كلمة المرور إلى بريدك الإلكتروني',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'تعذر إرسال رابط استعادة كلمة المرور';

      if (e.code == 'user-not-found') {
        message = 'لا يوجد حساب مسجل بهذا البريد الإلكتروني';
      } else if (e.code == 'invalid-email') {
        message = 'صيغة البريد الإلكتروني غير صحيحة';
      } else if (e.code == 'too-many-requests') {
        message = 'تمت محاولات كثيرة، حاول مرة أخرى لاحقاً';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ غير متوقع، حاول مرة أخرى')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isResettingPassword = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.removeListener(_refreshFocusState);
    passwordFocusNode.removeListener(_refreshFocusState);
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
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
                                Colors.white.withValues(alpha: 0.48),
                                Colors.white.withValues(alpha: 0.22),
                                Colors.white.withValues(alpha: 0.08),
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
                                Colors.white.withValues(alpha: 0.20),
                                Colors.white.withValues(alpha: 0.04),
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
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  16,
                                  18,
                                  16,
                                ),
                                child: Column(
                                  children: [
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: _TopBackButton(
                                        onTap: () => Navigator.pop(context),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const _BrandLogo(size: 104),
                                    const SizedBox(height: 15),
                                    const Text(
                                      'دخول العميل',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 31,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primaryDark,
                                        height: 1.15,
                                        shadows: [
                                          Shadow(
                                            color: Colors.white,
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    const Text(
                                      'سجل دخولك للوصول إلى حجوزاتك وإدارة مواعيد غسيل سيارتك بكل سهولة.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                        height: 1.55,
                                        shadows: [
                                          Shadow(
                                            color: Colors.white,
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    _LoginGlassCard(
                                      emailController: emailController,
                                      passwordController: passwordController,
                                      emailFocusNode: emailFocusNode,
                                      passwordFocusNode: passwordFocusNode,
                                      obscurePassword: obscurePassword,
                                      isLoading: isLoading,
                                      onTogglePassword: () {
                                        setState(() {
                                          obscurePassword = !obscurePassword;
                                        });
                                      },
                                      onForgotPassword:
                                          _showForgotPasswordMessage,
                                      onLogin: login,
                                      onCreateAccount: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const CustomerRegisterScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
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

class _LoginGlassCard extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onForgotPassword;
  final VoidCallback onLogin;
  final VoidCallback onCreateAccount;

  const _LoginGlassCard({
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onForgotPassword,
    required this.onLogin,
    required this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Column(
        children: [
          const _SectionTitle(
            title: 'بيانات الدخول',
            icon: Icons.account_circle,
          ),
          const SizedBox(height: 18),
          _GlassTextField(
            controller: emailController,
            focusNode: emailFocusNode,
            hintText: 'البريد الإلكتروني',
            icon: Icons.email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _GlassTextField(
            controller: passwordController,
            focusNode: passwordFocusNode,
            hintText: 'كلمة المرور',
            icon: Icons.lock_rounded,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onLogin(),
            suffixIcon: IconButton(
              tooltip: obscurePassword
                  ? 'إظهار كلمة المرور'
                  : 'إخفاء كلمة المرور',
              onPressed: onTogglePassword,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onForgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'نسيت كلمة المرور؟',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _PrimaryButton(
            text: 'تسجيل الدخول',
            icon: Icons.login_rounded,
            isLoading: isLoading,
            onPressed: onLogin,
          ),
          const SizedBox(height: 18),
          const _OrDivider(),
          const SizedBox(height: 18),
          _CreateAccountButton(onTap: onCreateAccount),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
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
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
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
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  const _GlassTextField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused ? AppColors.primary : const Color(0xFFD7EAFA),
          width: isFocused ? 1.6 : 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(
              alpha: isFocused ? 0.12 : 0.04,
            ),
            blurRadius: isFocused ? 14 : 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        onSubmitted: onSubmitted,
        cursorColor: AppColors.primary,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 14.5,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
          prefixIcon: Icon(icon, color: AppColors.primaryDark, size: 22),
          suffixIcon: suffixIcon,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.text,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool isHovering = false;
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => isPressed = true),
        onTapCancel: () => setState(() => isPressed = false),
        onTapUp: (_) => setState(() => isPressed = false),
        child: AnimatedScale(
          scale: isPressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 110),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: widget.isLoading ? null : widget.onPressed,
              icon: widget.isLoading
                  ? const SizedBox.shrink()
                  : Icon(widget.icon, size: 22),
              label: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(widget.text),
              style: ElevatedButton.styleFrom(
                elevation: isHovering ? 9 : 7,
                shadowColor: AppColors.primaryDark.withValues(alpha: 0.25),
                backgroundColor: isHovering
                    ? const Color(0xFF229BEA)
                    : AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.65,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateAccountButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CreateAccountButton({required this.onTap});

  @override
  State<_CreateAccountButton> createState() => _CreateAccountButtonState();
}

class _CreateAccountButtonState extends State<_CreateAccountButton> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovering = true),
      onExit: (_) => setState(() => isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isHovering
              ? Colors.white.withValues(alpha: 0.90)
              : Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(
                alpha: isHovering ? 0.13 : 0.06,
              ),
              blurRadius: isHovering ? 18 : 10,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppColors.primary,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ليس لديك حساب؟',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'إنشاء حساب جديد',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: AppColors.border.withValues(alpha: 0.8)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: Text(
              'أو',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        Expanded(
          child: Divider(color: AppColors.border.withValues(alpha: 0.8)),
        ),
      ],
    );
  }
}

class _TopBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _TopBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        onPressed: onTap,
        icon: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: AppColors.primaryDark,
          size: 21,
        ),
      ),
    );
  }
}

class _BrandLogo extends StatelessWidget {
  final double size;

  const _BrandLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.055),
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
          return Icon(
            Icons.local_car_wash_rounded,
            color: AppColors.primaryDark,
            size: size * 0.52,
          );
        },
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
