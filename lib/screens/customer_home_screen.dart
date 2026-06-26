import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../main.dart';
import '../services/session_service.dart';
import '../services/ads_service.dart';
import 'my_bookings_screen.dart';
import 'wash_list_screen.dart';
import 'customer_notifications_screen.dart';
import 'service_selection_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  static const Color _primary = Color(0xFF0D57B7);
  static const Color _secondary = Color(0xFF23A3F5);
  static const Color _darkText = Color(0xFF12345B);
  static const Color _mutedText = Color(0xFF64748B);
  static const double _frameMaxWidth = 520;

  late Future<int> _unreadCountFuture;
  late Future<List<Map<String, dynamic>>> _paidAdsFuture;

  @override
  void initState() {
    super.initState();
    _unreadCountFuture = _getUnreadNotificationsCount();
    _paidAdsFuture = _getActivePaidAds();
  }

  Future<void> _refreshData() async {
    setState(() {
      _unreadCountFuture = _getUnreadNotificationsCount();
      _paidAdsFuture = _getActivePaidAds();
    });

    await Future.wait([_unreadCountFuture, _paidAdsFuture]);
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    SessionService.currentCustomerId = '';
    SessionService.currentCustomerName = '';

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<int> _getUnreadNotificationsCount() async {
    final customerId = SessionService.currentCustomerId ?? '';

    if (customerId.isEmpty) return 0;

    final notificationSnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .get();

    final notifications = notificationSnapshot.docs.where((doc) {
      final data = doc.data();

      if (data['isActive'] == false) return false;

      final target = data['target']?.toString() ?? '';

      return target == 'all' ||
          target == 'customers' ||
          target == 'customer' ||
          target == 'specific_customer' ||
          target == 'العملاء' ||
          target == 'الكل' ||
          target.isEmpty;
    }).toList();

    final readSnapshot = await FirebaseFirestore.instance
        .collection('notification_reads')
        .where('userId', isEqualTo: customerId)
        .where('userType', isEqualTo: 'customer')
        .get();

    final readIds = readSnapshot.docs
        .map((doc) => doc.data()['notificationId']?.toString() ?? '')
        .toSet();

    return notifications.where((doc) => !readIds.contains(doc.id)).length;
  }

  Future<List<Map<String, dynamic>>> _getActivePaidAds() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('type', isEqualTo: 'paid_ad')
        .get();

    final docs = snapshot.docs.where((doc) {
      return AdsService.isCurrentlyActivePaidAd(doc.data());
    }).toList();

    docs.sort((a, b) {
      final aDate = a.data()['createdAt'];
      final bDate = b.data()['createdAt'];

      if (aDate is Timestamp && bDate is Timestamp) {
        return bDate.compareTo(aDate);
      }

      return 0;
    });

    return docs.map((doc) => doc.data()).toList();
  }

  Widget _notificationButton(BuildContext context) {
    return FutureBuilder<int>(
      future: _unreadCountFuture,
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            _CircleIconButton(
              icon: Icons.notifications_rounded,
              tooltip: 'الإشعارات',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerNotificationsScreen(),
                  ),
                );

                if (mounted) {
                  setState(() {
                    _unreadCountFuture = _getUnreadNotificationsCount();
                  });
                }
              },
            ),
            if (count > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  constraints: const BoxConstraints(minWidth: 19),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE11D48).withOpacity(0.26),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    count > 99 ? '99+' : count.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _paidAdsSection(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _paidAdsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SmallLoadingCard(title: 'جاري تحميل العروض...');
        }

        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final ads = snapshot.data ?? [];

        if (ads.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              title: 'عروض ممولة',
              subtitle: 'اختر العرض المناسب واحجز مباشرة',
              icon: Icons.campaign_rounded,
            ),
            const SizedBox(height: 12),
            ...ads.take(5).map((adData) => _paidAdCard(context, adData)),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  Widget _paidAdCard(BuildContext context, Map<String, dynamic> adData) {
    final title = adData['title']?.toString().trim() ?? 'عرض خاص';
    final body = adData['body']?.toString().trim() ?? '';
    final washId = adData['washId']?.toString() ?? '';
    final washName = adData['washName']?.toString().trim() ?? 'مغسلة';
    final startDate = AdsService.formatDate(adData['startAt']);
    final endDate = AdsService.formatDate(adData['endAt']);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.88),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.92)),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _secondary.withOpacity(0.13),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD9ECFF)),
                      ),
                      child: const Icon(
                        Icons.local_car_wash_rounded,
                        color: _primary,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            washName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _darkText,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7E8),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFFFCC80),
                              ),
                            ),
                            child: const Text(
                              'إعلان ممول',
                              style: TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title.isEmpty ? 'عرض خاص' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _darkText,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _mutedText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.76),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFFD9ECFF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.date_range_rounded,
                        size: 17,
                        color: _primary,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'مدة العرض: $startDate إلى $endDate',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _mutedText,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _GradientActionButton(
                  title: 'احجز الآن',
                  icon: Icons.arrow_back_rounded,
                  height: 48,
                  enabled: washId.isNotEmpty,
                  onTap: washId.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ServiceSelectionScreen(
                                washId: washId,
                                washName: washName,
                              ),
                            ),
                          );
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final customerName = SessionService.currentCustomerName ?? '';
    final greetingName = customerName.trim().isEmpty ? 'عميلنا' : customerName;

    return _GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/logo_mawed_ghaseel.png',
                width: 62,
                height: 62,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أهلاً $greetingName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _darkText,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'احجز موعد غسيل سيارتك وتابع حجوزاتك بكل سهولة.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _mutedText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(
                child: _MiniFeature(
                  icon: Icons.verified_rounded,
                  title: 'مغاسل معتمدة',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MiniFeature(
                  icon: Icons.timer_rounded,
                  title: 'حجز سريع',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MiniFeature(
                  icon: Icons.notifications_active_rounded,
                  title: 'تنبيهات فورية',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'الخدمات السريعة',
          subtitle: 'كل ما تحتاجه لإدارة حجوزاتك',
          icon: Icons.dashboard_customize_rounded,
        ),
        const SizedBox(height: 12),
        _HomeActionCard(
          title: 'حجز موعد جديد',
          subtitle: 'اختر المغسلة والخدمة والوقت المناسب لك.',
          icon: Icons.add_circle_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WashListScreen()),
            );
          },
        ),
        const SizedBox(height: 10),
        _HomeActionCard(
          title: 'مواعيدي',
          subtitle: 'تابع حجوزاتك الحالية والسابقة وحالة الموافقة.',
          icon: Icons.event_available_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyBookingsScreen()),
            );
          },
        ),
        const SizedBox(height: 10),
        const _DisabledHomeActionCard(
          title: 'العروض',
          subtitle: 'خصومات وعروض مميزة ستتوفر قريباً.',
          icon: Icons.local_offer_rounded,
        ),
        const SizedBox(height: 10),
        const _DisabledHomeActionCard(
          title: 'التقييمات',
          subtitle: 'تقييم المغاسل وتجربة الخدمة ستتوفر قريباً.',
          icon: Icons.star_rounded,
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    return RefreshIndicator(
      color: _primary,
      onRefresh: _refreshData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: [
          _TopBar(
            notificationButton: _notificationButton(context),
            onLogout: () => _logout(context),
          ),
          const SizedBox(height: 16),
          _header(),
          const SizedBox(height: 16),
          _paidAdsSection(context),
          _quickActions(context),
          const SizedBox(height: 18),
          _GradientActionButton(
            title: 'تسجيل الخروج',
            icon: Icons.logout_rounded,
            danger: true,
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFEAF6FF),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= 700;
            final double frameWidth = isWide
                ? _frameMaxWidth
                : constraints.maxWidth;
            final BorderRadius frameRadius = isWide
                ? BorderRadius.circular(30)
                : BorderRadius.zero;

            return Center(
              child: SizedBox(
                width: frameWidth,
                height: constraints.maxHeight,
                child: ClipRRect(
                  borderRadius: frameRadius,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/welcome_background.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.74),
                                Colors.white.withOpacity(0.84),
                                const Color(0xFFEAF6FF).withOpacity(0.92),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -42,
                        right: -44,
                        child: _SoftCircle(size: 148, opacity: 0.10),
                      ),
                      Positioned(
                        top: 250,
                        left: -60,
                        child: _SoftCircle(size: 142, opacity: 0.08),
                      ),
                      Positioned(
                        bottom: 50,
                        right: -38,
                        child: _SoftCircle(size: 134, opacity: 0.08),
                      ),
                      SafeArea(child: _buildContent(context)),
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

class _TopBar extends StatelessWidget {
  final Widget notificationButton;
  final VoidCallback onLogout;

  const _TopBar({required this.notificationButton, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconButton(
          icon: Icons.logout_rounded,
          tooltip: 'تسجيل الخروج',
          onTap: onLogout,
        ),
        const SizedBox(width: 10),
        notificationButton,
        const Spacer(),
        const Text(
          'لوحة العميل',
          style: TextStyle(
            color: _CustomerHomeScreenState._darkText,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = const BorderRadius.all(Radius.circular(26)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: _CustomerHomeScreenState._primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.84),
              borderRadius: borderRadius,
              border: Border.all(color: Colors.white.withOpacity(0.84)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SmallLoadingCard extends StatelessWidget {
  final String title;

  const _SmallLoadingCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.80),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.82)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: _CustomerHomeScreenState._primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: _CustomerHomeScreenState._mutedText,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                _CustomerHomeScreenState._secondary,
                _CustomerHomeScreenState._primary,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _CustomerHomeScreenState._primary.withOpacity(0.16),
                blurRadius: 15,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _CustomerHomeScreenState._darkText,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _CustomerHomeScreenState._mutedText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.86),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD9ECFF)),
            boxShadow: [
              BoxShadow(
                color: _CustomerHomeScreenState._primary.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _ActionIcon(icon: icon, active: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _CustomerHomeScreenState._darkText,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _CustomerHomeScreenState._mutedText,
                        fontSize: 12.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _CustomerHomeScreenState._primary,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisabledHomeActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _DisabledHomeActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.70,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.78),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD9ECFF)),
          boxShadow: [
            BoxShadow(
              color: _CustomerHomeScreenState._primary.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            _ActionIcon(icon: icon, active: false),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _CustomerHomeScreenState._darkText,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF6FF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFD9ECFF)),
                        ),
                        child: const Text(
                          'قريباً',
                          style: TextStyle(
                            color: _CustomerHomeScreenState._primary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _CustomerHomeScreenState._mutedText,
                      fontSize: 12.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final bool active;

  const _ActionIcon({required this.icon, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  _CustomerHomeScreenState._secondary,
                  _CustomerHomeScreenState._primary,
                ],
              )
            : null,
        color: active
            ? null
            : _CustomerHomeScreenState._secondary.withOpacity(0.14),
        borderRadius: BorderRadius.circular(17),
        border: active
            ? null
            : Border.all(color: Colors.white.withOpacity(0.86)),
        boxShadow: active
            ? [
                BoxShadow(
                  color: _CustomerHomeScreenState._primary.withOpacity(0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        color: active ? Colors.white : _CustomerHomeScreenState._primary,
        size: 26,
      ),
    );
  }
}

class _GradientActionButton extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;
  final bool danger;
  final double height;

  const _GradientActionButton({
    required this.title,
    required this.icon,
    required this.onTap,
    this.enabled = true,
    this.danger = false,
    this.height = 54,
  });

  @override
  State<_GradientActionButton> createState() => _GradientActionButtonState();
}

class _GradientActionButtonState extends State<_GradientActionButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = widget.enabled && widget.onTap != null;
    final List<Color> colors = widget.danger
        ? const [Color(0xFFEF4444), Color(0xFFB91C1C)]
        : const [
            _CustomerHomeScreenState._secondary,
            _CustomerHomeScreenState._primary,
          ];

    return MouseRegion(
      cursor: active ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: active ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: active ? () => setState(() => _pressed = false) : null,
        onTapUp: active
            ? (_) {
                setState(() => _pressed = false);
                widget.onTap?.call();
              }
            : null,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 130),
          scale: _pressed ? 0.985 : (_hovered && active ? 1.01 : 1),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: active ? 1 : 0.50,
            child: Container(
              width: double.infinity,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: colors,
                ),
                borderRadius: BorderRadius.circular(17),
                boxShadow: [
                  BoxShadow(
                    color: colors.last.withOpacity(_hovered ? 0.28 : 0.18),
                    blurRadius: _hovered ? 20 : 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(widget.icon, color: Colors.white, size: 21),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_CircleIconButton> createState() => _CircleIconButtonState();
}

class _CircleIconButtonState extends State<_CircleIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _hovered ? Colors.white : Colors.white.withOpacity(0.82),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.90)),
              boxShadow: [
                BoxShadow(
                  color: _CustomerHomeScreenState._primary.withOpacity(
                    _hovered ? 0.16 : 0.08,
                  ),
                  blurRadius: _hovered ? 17 : 11,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              color: _CustomerHomeScreenState._primary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniFeature extends StatelessWidget {
  final IconData icon;
  final String title;

  const _MiniFeature({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.66),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFD9ECFF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _CustomerHomeScreenState._primary, size: 21),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _CustomerHomeScreenState._darkText,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _SoftCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _CustomerHomeScreenState._secondary.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
