import 'package:flutter/material.dart';

import '../services/firebase_auth_service.dart';
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
  bool obscurePassword = true;

  static const Color primaryBlue = Color(0xFF0F56B3);
  static const Color brightBlue = Color(0xFF2196E8);
  static const Color softBackground = Color(0xFFEAF6FF);
  static const Color textDark = Color(0xFF0D2B4F);
  static const Color textMuted = Color(0xFF63758D);
  static const Color borderColor = Color(0xFFD9E9F7);

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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CustomerHomeScreen()),
    );
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
        backgroundColor: softBackground,
        body: Stack(
          children: [
            const _PremiumBackground(),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _HeaderCard(onBack: () => Navigator.pop(context)),
                        const SizedBox(height: 20),
                        _LoginCard(
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumBackground extends StatelessWidget {
  const _PremiumBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEAF6FF), Color(0xFFF8FCFF), Color(0xFFEFF8FF)],
            ),
          ),
        ),
        Positioned(
          top: -85,
          right: -70,
          child: _BlurCircle(
            size: 190,
            color: const Color(0xFF69BDF4).withAlpha(74),
          ),
        ),
        Positioned(
          top: 240,
          left: -100,
          child: _BlurCircle(
            size: 210,
            color: const Color(0xFF4BB7E8).withAlpha(50),
          ),
        ),
        Positioned(
          bottom: -80,
          right: -70,
          child: _BlurCircle(
            size: 200,
            color: const Color(0xFF0F56B3).withAlpha(31),
          ),
        ),
      ],
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _BlurCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final VoidCallback onBack;

  const _HeaderCard({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F56B3).withAlpha(20),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: _CircleIconButton(
              icon: Icons.arrow_forward_ios_rounded,
              onTap: onBack,
            ),
          ),
          Column(
            children: [
              const _BrandLogo(size: 96),
              const SizedBox(height: 18),
              const Text(
                'أهلاً بك في موعد غسيل',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _CustomerLoginScreenState.primaryBlue,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'سجل دخولك للوصول إلى حجوزاتك وإدارة مواعيد غسيل سيارتك بكل سهولة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _CustomerLoginScreenState.textMuted,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF2F8FF),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            color: _CustomerLoginScreenState.primaryBlue,
            size: 18,
          ),
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
      padding: EdgeInsets.all(size * 0.08),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD8ECFF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F56B3).withAlpha(32),
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
            color: _CustomerLoginScreenState.brightBlue,
            size: 48,
          );
        },
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onCreateAccount;

  const _LoginCard({
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F56B3).withAlpha(24),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle_rounded,
                color: _CustomerLoginScreenState.brightBlue,
                size: 27,
              ),
              SizedBox(width: 8),
              Text(
                'بيانات الدخول',
                style: TextStyle(
                  color: _CustomerLoginScreenState.primaryBlue,
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          _PremiumTextField(
            controller: emailController,
            focusNode: emailFocusNode,
            hintText: 'البريد الإلكتروني',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_rounded,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => passwordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 14),
          _PremiumTextField(
            controller: passwordController,
            focusNode: passwordFocusNode,
            hintText: 'كلمة المرور',
            prefixIcon: Icons.lock_rounded,
            obscureText: obscurePassword,
            suffixIcon: obscurePassword
                ? Icons.visibility_off_rounded
                : Icons.visibility_rounded,
            onSuffixTap: onTogglePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onLogin(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : () {},
              style: TextButton.styleFrom(
                foregroundColor: _CustomerLoginScreenState.textMuted,
                padding: EdgeInsets.zero,
                minimumSize: const Size(10, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'نسيت كلمة المرور؟',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _LoginButton(isLoading: isLoading, onPressed: onLogin),
          const SizedBox(height: 22),
          const _OrDivider(),
          const SizedBox(height: 22),
          _CreateAccountCard(isLoading: isLoading, onPressed: onCreateAccount),
        ],
      ),
    );
  }
}

class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final IconData prefixIcon;
  final IconData? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final VoidCallback? onSuffixTap;
  final ValueChanged<String>? onSubmitted;

  const _PremiumTextField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.onSuffixTap,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: _CustomerLoginScreenState.brightBlue.withAlpha(38),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: const TextStyle(
          color: _CustomerLoginScreenState.textDark,
          fontSize: 15.5,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: _CustomerLoginScreenState.textMuted,
            fontWeight: FontWeight.w700,
          ),
          filled: true,
          fillColor: isFocused ? Colors.white : const Color(0xFFF8FBFF),
          prefixIcon: Icon(
            prefixIcon,
            color: isFocused
                ? _CustomerLoginScreenState.brightBlue
                : _CustomerLoginScreenState.primaryBlue,
          ),
          suffixIcon: suffixIcon == null
              ? null
              : IconButton(
                  onPressed: onSuffixTap,
                  icon: Icon(
                    suffixIcon,
                    color: isFocused
                        ? _CustomerLoginScreenState.brightBlue
                        : _CustomerLoginScreenState.textMuted,
                  ),
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: _CustomerLoginScreenState.borderColor,
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: _CustomerLoginScreenState.brightBlue,
              width: 1.6,
            ),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoginButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: isLoading ? 0.85 : 1,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [
              _CustomerLoginScreenState.brightBlue,
              _CustomerLoginScreenState.primaryBlue,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: _CustomerLoginScreenState.primaryBlue.withAlpha(62),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: isLoading ? null : onPressed,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 25,
                      height: 25,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.7,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.login_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 9),
                        Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.5,
                            fontWeight: FontWeight.w900,
                          ),
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
    return const Row(
      children: [
        Expanded(child: Divider(color: Color(0xFFE2EEF8), thickness: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'أو',
            style: TextStyle(
              color: _CustomerLoginScreenState.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(child: Divider(color: Color(0xFFE2EEF8), thickness: 1)),
      ],
    );
  }
}

class _CreateAccountCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _CreateAccountCard({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4FAFF),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: isLoading ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD9ECFC), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      _CustomerLoginScreenState.brightBlue,
                      _CustomerLoginScreenState.primaryBlue,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ليس لديك حساب؟',
                      style: TextStyle(
                        color: _CustomerLoginScreenState.textMuted,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'إنشاء حساب جديد',
                      style: TextStyle(
                        color: _CustomerLoginScreenState.primaryBlue,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
