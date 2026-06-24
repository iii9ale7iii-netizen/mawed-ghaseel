class BookingModel {
  String bookingId;

  String customerId;
  String customerName;

  String washId;
  String washName;

  String serviceName;

  String date;
  String time;

  String status;

  BookingModel({
    required this.bookingId,
    required this.customerId,
    required this.customerName,
    required this.washId,
    required this.washName,
    required this.serviceName,
    required this.date,
    required this.time,
    this.status = 'بانتظار الموافقة',
  });
}
