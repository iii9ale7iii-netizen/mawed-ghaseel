import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/session_service.dart';
import '../services/working_hours_service.dart';
import '../theme/app_glass_ui.dart';

class BookingScreen extends StatefulWidget {
  final String washId;
  final String washName;
  final String serviceName;

  const BookingScreen({
    super.key,
    required this.washId,
    required this.washName,
    required this.serviceName,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  final TextEditingController couponController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool isLoading = false;
  bool isCheckingCoupon = false;

  String appliedCouponCode = '';
  int discountPercentage = 0;
  bool couponApplied = false;

  Future<void> selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
        dateController.text =
            '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
      });
    }
  }

  Future<void> selectTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (pickedTime != null && mounted) {
      setState(() {
        selectedTime = pickedTime;
        timeController.text = pickedTime.format(context);
      });
    }
  }

  DateTime? selectedBookingDateTime() {
    if (selectedDate == null || selectedTime == null) return null;

    return DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
  }

  Future<bool> validateWorkingHours() async {
    final bookingDateTime = selectedBookingDateTime();

    if (bookingDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار التاريخ والوقت')),
      );
      return false;
    }

    final washDoc = await FirebaseFirestore.instance
        .collection('washes')
        .doc(widget.washId)
        .get();

    if (!washDoc.exists) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المغسلة غير موجودة')),
      );
      return false;
    }

    final washData = washDoc.data() ?? {};
    final bookingEnabled = WorkingHoursService.isWashBookingEnabled(washData);

    if (!bookingEnabled) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('المغسلة لا تستقبل حجوزات حالياً')),
      );
      return false;
    }

    final workingHours = WorkingHoursService.getWorkingHours(washData);
    final dayKey = WorkingHoursService.dayKeyFromDate(bookingDateTime);
    final dayDataRaw = workingHours[dayKey];

    if (dayDataRaw is! Map) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا توجد أوقات عمل لهذا اليوم')),
      );
      return false;
    }

    final dayData = Map<String, dynamic>.from(dayDataRaw);
    final dayEnabled = dayData['enabled'] == true;

    if (!dayEnabled) {
      if (!mounted) return false;

      final dayName = WorkingHoursService.arabicDayName(dayKey);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('المغسلة مغلقة يوم $dayName')),
      );
      return false;
    }

    final from = dayData['from']?.toString() ?? '00:00';
    final to = dayData['to']?.toString() ?? '00:00';
    final isOpen = WorkingHoursService.isOpenAt(
      washData: washData,
      dateTime: bookingDateTime,
    );

    if (!isOpen) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'الوقت المختار خارج أوقات العمل. وقت العمل من $from إلى $to',
          ),
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> applyCoupon() async {
    final code = couponController.text.trim().toUpperCase();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال كود الخصم')),
      );
      return;
    }

    setState(() {
      isCheckingCoupon = true;
    });

    try {
      final couponSnapshot = await FirebaseFirestore.instance
          .collection('coupons')
          .where('code', isEqualTo: code)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (!mounted) return;

      if (couponSnapshot.docs.isEmpty) {
        setState(() {
          appliedCouponCode = '';
          discountPercentage = 0;
          couponApplied = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('كود الخصم غير صحيح أو غير فعال')),
        );
        return;
      }

      final data = couponSnapshot.docs.first.data();
      final discount = data['discount'] ?? 0;

      setState(() {
        appliedCouponCode = code;
        discountPercentage = discount is int
            ? discount
            : int.tryParse(discount.toString()) ?? 0;
        couponApplied = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تطبيق خصم $discountPercentage%')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          isCheckingCoupon = false;
        });
      }
    }
  }

  Future<void> saveBooking() async {
    if (dateController.text.isEmpty || timeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار التاريخ والوقت')),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final isValidWorkingTime = await validateWorkingHours();

      if (!mounted) return;

      if (!isValidWorkingTime) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final existingBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('washId', isEqualTo: widget.washId)
          .where('date', isEqualTo: dateController.text)
          .where('time', isEqualTo: timeController.text)
          .get();

      bool booked = false;

      for (final doc in existingBookings.docs) {
        final data = doc.data();

        if (data['status'] != 'مرفوض' && data['status'] != 'ظ…ط±ظپظˆط¶') {
          booked = true;
          break;
        }
      }

      if (!mounted) return;

      if (booked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('هذا الموعد محجوز مسبقاً')),
        );

        setState(() {
          isLoading = false;
        });

        return;
      }

      await FirebaseFirestore.instance.collection('bookings').add({
        'customerId': SessionService.currentCustomerId ?? '',
        'customerName': SessionService.currentCustomerName ?? '',
        'washId': widget.washId,
        'washName': widget.washName,
        'serviceName': widget.serviceName,
        'date': dateController.text,
        'time': timeController.text,
        'status': 'بانتظار الموافقة',
        'couponCode': couponApplied ? appliedCouponCode : '',
        'discountPercentage': couponApplied ? discountPercentage : 0,
        'hasDiscount': couponApplied,
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الطلب للمغسلة بنجاح')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    dateController.dispose();
    timeController.dispose();
    couponController.dispose();
    super.dispose();
  }

  Widget _bookingField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    VoidCallback? onTap,
    bool readOnly = false,
    bool enabled = true,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      enabled: enabled,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppGlassUi.primary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
      ),
    );
  }

  Widget _couponAppliedCard() {
    return AppGlassCard(
      padding: const EdgeInsets.all(14),
      color: Colors.green.withValues(alpha: 0.10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تم تطبيق الكود: $appliedCouponCode',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppGlassUi.darkText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'نسبة الخصم: $discountPercentage%',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                couponController.clear();
                appliedCouponCode = '';
                discountPercentage = 0;
                couponApplied = false;
              });
            },
            child: const Text('إزالة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppGlassScaffold(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppGlassTopBar(
              title: widget.washName,
              leadingIcon: Icons.arrow_back_rounded,
              leadingTooltip: 'رجوع',
            ),
            const SizedBox(height: 18),
            AppGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionTitle(
                    title: 'تأكيد الحجز',
                    subtitle: 'اختر التاريخ والوقت المناسبين لك',
                    icon: Icons.event_available_rounded,
                  ),
                  const SizedBox(height: 14),
                  AppInfoRow(
                    icon: Icons.local_car_wash_rounded,
                    text: 'المغسلة: ${widget.washName}',
                  ),
                  AppInfoRow(
                    icon: Icons.design_services_rounded,
                    text: 'الخدمة المختارة: ${widget.serviceName}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppGlassCard(
              child: Column(
                children: [
                  _bookingField(
                    controller: dateController,
                    label: 'اختر التاريخ',
                    icon: Icons.calendar_month_rounded,
                    readOnly: true,
                    onTap: selectDate,
                    suffixIcon: const Icon(Icons.expand_more_rounded),
                  ),
                  const SizedBox(height: 12),
                  _bookingField(
                    controller: timeController,
                    label: 'اختر الوقت',
                    icon: Icons.access_time_rounded,
                    readOnly: true,
                    onTap: selectTime,
                    suffixIcon: const Icon(Icons.expand_more_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppGlassCard(
              child: Column(
                children: [
                  _bookingField(
                    controller: couponController,
                    label: 'كود الخصم اختياري',
                    hintText: 'مثال: WASH20',
                    icon: Icons.local_offer_rounded,
                    enabled: !couponApplied,
                    suffixIcon: couponApplied
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.discount_rounded),
                  ),
                  const SizedBox(height: 12),
                  AppGradientButton(
                    title: couponApplied ? 'تم تطبيق الخصم' : 'تطبيق الخصم',
                    icon: couponApplied
                        ? Icons.check_rounded
                        : Icons.local_offer_rounded,
                    onTap: isCheckingCoupon || couponApplied ? null : applyCoupon,
                  ),
                ],
              ),
            ),
            if (couponApplied) ...[
              const SizedBox(height: 12),
              _couponAppliedCard(),
            ],
            const SizedBox(height: 18),
            AppGradientButton(
              title: isLoading ? 'جاري تأكيد الحجز...' : 'تأكيد الحجز',
              icon: Icons.check_circle_rounded,
              onTap: isLoading ? null : saveBooking,
            ),
          ],
        ),
      ),
    );
  }
}
