import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/session_service.dart';
import '../services/working_hours_service.dart';
import '../theme/app_glass_ui.dart';

class WorkingHoursScreen extends StatefulWidget {
  const WorkingHoursScreen({super.key});

  @override
  State<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends State<WorkingHoursScreen> {
  bool isLoading = true;
  bool isSaving = false;
  bool bookingEnabled = true;

  Map<String, dynamic> workingHours =
      WorkingHoursService.defaultWorkingHoursMap();

  @override
  void initState() {
    super.initState();
    loadWorkingHours();
  }

  Future<void> loadWorkingHours() async {
    final washId = SessionService.currentWashId ?? '';

    if (washId.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    await WorkingHoursService.initializeWashWorkingHoursIfMissing(washId);

    final doc = await FirebaseFirestore.instance
        .collection('washes')
        .doc(washId)
        .get();

    final data = doc.data() ?? {};

    setState(() {
      bookingEnabled = WorkingHoursService.isWashBookingEnabled(data);
      workingHours = WorkingHoursService.getWorkingHours(data);
      isLoading = false;
    });
  }

  Future<void> saveWorkingHours() async {
    final washId = SessionService.currentWashId ?? '';

    if (washId.isEmpty) return;

    setState(() {
      isSaving = true;
    });

    await WorkingHoursService.updateBookingEnabled(
      washId: washId,
      enabled: bookingEnabled,
    );

    await WorkingHoursService.updateWorkingHours(
      washId: washId,
      workingHours: workingHours,
    );

    setState(() {
      isSaving = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ أوقات العمل بنجاح')),
    );
  }

  Future<void> pickTime({required String dayKey, required String field}) async {
    final dayData = Map<String, dynamic>.from(workingHours[dayKey] ?? {});
    final currentValue = dayData[field]?.toString() ?? '08:00';

    final parts = currentValue.split(':');
    final initialHour = int.tryParse(parts.first) ?? 8;
    final initialMinute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (time == null) return;

    final formatted =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    setState(() {
      dayData[field] = formatted;
      workingHours[dayKey] = dayData;
    });
  }

  Widget bookingEnabledCard() {
    return AppGlassCard(
      child: Row(
        children: [
          const AppActionIcon(icon: Icons.event_available_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'استقبال الحجوزات',
                  style: TextStyle(
                    color: AppGlassUi.darkText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bookingEnabled
                      ? 'المغسلة تستقبل حجوزات حالياً'
                      : 'المغسلة لا تستقبل حجوزات حالياً',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppGlassUi.mutedText,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: bookingEnabled,
            activeThumbColor: AppGlassUi.primary,
            onChanged: (value) {
              setState(() {
                bookingEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _timeButton({
    required String title,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.access_time_rounded, size: 18),
      label: FittedBox(child: Text(title)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppGlassUi.primary,
        backgroundColor: Colors.white.withValues(alpha: 0.66),
        side: const BorderSide(color: Color(0xFFD9ECFF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );
  }

  Widget dayCard(String dayKey) {
    final dayData = Map<String, dynamic>.from(workingHours[dayKey] ?? {});
    final enabled = dayData['enabled'] == true;
    final from = dayData['from']?.toString() ?? '08:00';
    final to = dayData['to']?.toString() ?? '23:00';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppGlassCard(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                AppActionIcon(
                  icon: enabled ? Icons.today_rounded : Icons.event_busy_rounded,
                  active: enabled,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        WorkingHoursService.arabicDayName(dayKey),
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
                        enabled ? 'يوم عمل' : 'مغلق',
                        style: TextStyle(
                          color: enabled ? Colors.green : Colors.red,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  activeThumbColor: AppGlassUi.primary,
                  onChanged: (value) {
                    setState(() {
                      dayData['enabled'] = value;
                      workingHours[dayKey] = dayData;
                    });
                  },
                ),
              ],
            ),
            if (enabled) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _timeButton(
                      title: 'من: $from',
                      onPressed: () => pickTime(dayKey: dayKey, field: 'from'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _timeButton(
                      title: 'إلى: $to',
                      onPressed: () => pickTime(dayKey: dayKey, field: 'to'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<String> get daysOrder => const [
        'saturday',
        'sunday',
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
      ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppGlassScaffold(
        child: isLoading
            ? const AppLoadingState()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppGlassTopBar(
                    title: 'أوقات العمل',
                    leadingIcon: Icons.arrow_back_rounded,
                    leadingTooltip: 'رجوع',
                  ),
                  const SizedBox(height: 18),
                  bookingEnabledCard(),
                  const SizedBox(height: 18),
                  const AppSectionTitle(
                    title: 'الأيام والساعات',
                    subtitle: 'حدد مواعيد استقبال الحجوزات',
                    icon: Icons.schedule_rounded,
                  ),
                  const SizedBox(height: 12),
                  ...daysOrder.map(dayCard),
                  const SizedBox(height: 4),
                  AppGradientButton(
                    title: isSaving ? 'جاري الحفظ...' : 'حفظ أوقات العمل',
                    icon: Icons.save_rounded,
                    onTap: isSaving ? null : saveWorkingHours,
                  ),
                ],
              ),
      ),
    );
  }
}
