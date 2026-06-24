import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/session_service.dart';

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

  bool isLoading = false;

  Future<void> selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        dateController.text =
            '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
      });
    }
  }

  Future<void> selectTime() async {
    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        timeController.text = pickedTime.format(context);
      });
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

      final existingBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('washId', isEqualTo: widget.washId)
          .where('date', isEqualTo: dateController.text)
          .where('time', isEqualTo: timeController.text)
          .get();

      bool booked = false;

      for (var doc in existingBookings.docs) {
        final data = doc.data();

        if (data['status'] != 'مرفوض') {
          booked = true;
          break;
        }
      }

      if (booked) {
        if (!mounted) return;

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
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الطلب للمغسلة بنجاح')),
      );

      Navigator.pop(context);
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
        appBar: AppBar(title: Text(widget.washName), centerTitle: true),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'الخدمة المختارة: ${widget.serviceName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: dateController,
                readOnly: true,
                onTap: selectDate,
                decoration: const InputDecoration(
                  labelText: 'اختر التاريخ',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_month),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: timeController,
                readOnly: true,
                onTap: selectTime,
                decoration: const InputDecoration(
                  labelText: 'اختر الوقت',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : saveBooking,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('تأكيد الحجز'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
