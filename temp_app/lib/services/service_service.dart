import '../models/service_model.dart';

class ServiceService {
  static List<ServiceModel> services = [
    ServiceModel(
      serviceId: '1',
      serviceName: 'غسيل عادي',
      price: 25,
      durationMinutes: 30,
    ),
    ServiceModel(
      serviceId: '2',
      serviceName: 'غسيل VIP',
      price: 60,
      durationMinutes: 60,
    ),
    ServiceModel(
      serviceId: '3',
      serviceName: 'تلميع',
      price: 120,
      durationMinutes: 90,
    ),
    ServiceModel(
      serviceId: '4',
      serviceName: 'تنظيف داخلي',
      price: 80,
      durationMinutes: 45,
    ),
  ];
}
