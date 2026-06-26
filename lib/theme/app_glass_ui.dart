import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppGlassUi {
  AppGlassUi._();

  static const Color primary = Color(0xFF0D57B7);
  static const Color secondary = Color(0xFF23A3F5);
  static const Color darkText = Color(0xFF12345B);
  static const Color mutedText = Color(0xFF64748B);
  static const double frameMaxWidth = 520;
}

class AppGlassScaffold extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  const AppGlassScaffold({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 28),
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF5FF),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final frameWidth = constraints.maxWidth > AppGlassUi.frameMaxWidth
              ? AppGlassUi.frameMaxWidth
              : constraints.maxWidth;
          final mediaPadding = MediaQuery.paddingOf(context);
          final content = Padding(
            padding: padding,
            child: scrollable
                ? SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight -
                            mediaPadding.top -
                            mediaPadding.bottom,
                      ),
                      child: child,
                    ),
                  )
                : child,
          );

          return Center(
            child: SizedBox(
              width: frameWidth,
              height: constraints.maxHeight,
              child: ClipRRect(
                borderRadius: constraints.maxWidth > AppGlassUi.frameMaxWidth
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
                              Colors.white.withValues(alpha: 0.74),
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
                        child: content,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AppGlassTopBar extends StatelessWidget {
  final String title;
  final IconData? leadingIcon;
  final String? leadingTooltip;
  final VoidCallback? onLeadingTap;
  final List<Widget> actions;

  const AppGlassTopBar({
    super.key,
    required this.title,
    this.leadingIcon,
    this.leadingTooltip,
    this.onLeadingTap,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leadingIcon != null)
          AppCircleIconButton(
            icon: leadingIcon!,
            tooltip: leadingTooltip ?? '',
            onTap: onLeadingTap ?? () => Navigator.maybePop(context),
          ),
        if (leadingIcon != null) const SizedBox(width: 10),
        ...actions.expand((action) => [action, const SizedBox(width: 10)]),
        const Spacer(),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppGlassUi.darkText,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final Color? color;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = const BorderRadius.all(Radius.circular(26)),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: AppGlassUi.primary.withValues(alpha: 0.08),
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
              color: color ?? Colors.white.withValues(alpha: 0.86),
              borderRadius: borderRadius,
              border: Border.all(color: Colors.white.withValues(alpha: 0.84)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AppSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const AppSectionTitle({
    super.key,
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
              colors: [AppGlassUi.secondary, AppGlassUi.primary],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppGlassUi.primary.withValues(alpha: 0.16),
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
                  color: AppGlassUi.darkText,
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
                  color: AppGlassUi.mutedText,
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

class AppActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  const AppActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.trailing,
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
            color: Colors.white.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD9ECFF)),
            boxShadow: [
              BoxShadow(
                color: AppGlassUi.primary.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              AppActionIcon(icon: icon),
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
                        color: AppGlassUi.darkText,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppGlassUi.mutedText,
                        fontSize: 12.2,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ??
                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppGlassUi.primary,
                    size: 17,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppActionIcon extends StatelessWidget {
  final IconData icon;
  final bool active;

  const AppActionIcon({super.key, required this.icon, this.active = true});

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
                colors: [AppGlassUi.secondary, AppGlassUi.primary],
              )
            : null,
        color: active ? null : AppGlassUi.secondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(17),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppGlassUi.primary.withValues(alpha: 0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ]
            : null,
      ),
      child: Icon(icon, color: active ? Colors.white : AppGlassUi.primary),
    );
  }
}

class AppGradientButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final bool danger;
  final double height;

  const AppGradientButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.danger = false,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final colors = danger
        ? const [Color(0xFFEF4444), Color(0xFFB91C1C)]
        : const [AppGlassUi.secondary, AppGlassUi.primary];

    return Opacity(
      opacity: enabled ? 1 : 0.52,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(17),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(17),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, color: Colors.white, size: 21),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppCircleIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const AppCircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.84),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.90)),
              boxShadow: [
                BoxShadow(
                  color: AppGlassUi.primary.withValues(alpha: 0.08),
                  blurRadius: 11,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: AppGlassUi.primary, size: 22),
          ),
        ),
      ),
    );
  }
}

class AppStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const AppStatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class AppInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const AppInfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? AppGlassUi.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color ?? AppGlassUi.mutedText,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  final String title;
  final IconData icon;

  const AppEmptyState({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppGlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppActionIcon(icon: icon, active: false),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppGlassUi.darkText,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppLoadingState extends StatelessWidget {
  final String title;

  const AppLoadingState({super.key, this.title = 'جاري التحميل...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppGlassUi.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: AppGlassUi.mutedText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
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
