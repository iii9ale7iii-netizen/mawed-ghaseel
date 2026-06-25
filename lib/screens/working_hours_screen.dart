import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/session_service.dart';
import '../services/working_hours_service.dart';

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

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم حفظ أوقات العمل بنجاح')));
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
    return Card(
      child: SwitchListTile(
        title: const Text(
          'استقبال الحجوزات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          bookingEnabled
              ? 'المغسلة تستقبل حجوزات حالياً'
              : 'المغسلة لا تستقبل حجوزات حالياً',
        ),
        value: bookingEnabled,
        onChanged: (value) {
          setState(() {
            bookingEnabled = value;
          });
        },
      ),
    );
  }

  Widget dayCard(String dayKey) {
    final dayData = Map<String, dynamic>.from(workingHours[dayKey] ?? {});
    final enabled = dayData['enabled'] == true;
    final from = dayData['from']?.toString() ?? '08:00';
    final to = dayData['to']?.toString() ?? '23:00';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            SwitchListTile(
              title: Text(
                WorkingHoursService.arabicDayName(dayKey),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(enabled ? 'يوم عمل' : 'مغلق'),
              value: enabled,
              onChanged: (value) {
                setState(() {
                  dayData['enabled'] = value;
                  workingHours[dayKey] = dayData;
                });
              },
            ),
            if (enabled) ...[
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        pickTime(dayKey: dayKey, field: 'from');
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text('من: $from'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        pickTime(dayKey: dayKey, field: 'to');
                      },
                      icon: const Icon(Icons.access_time),
                      label: Text('إلى: $to'),
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
      child: Scaffold(
        appBar: AppBar(title: const Text('أوقات العمل'), centerTitle: true),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  bookingEnabledCard(),
                  const SizedBox(height: 10),
                  const Text(
                    'تحديد أيام وساعات العمل',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...daysOrder.map(dayCard),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : saveWorkingHours,
                      icon: const Icon(Icons.save),
                      label: isSaving
                          ? const Text('جاري الحفظ...')
                          : const Text('حفظ أوقات العمل'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
