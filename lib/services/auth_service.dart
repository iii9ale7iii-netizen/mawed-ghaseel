import 'session_service.dart';

class AuthService {
  static void loginCustomer({
    required String customerId,
    required String customerName,
  }) {
    SessionService.currentCustomerId = customerId;
    SessionService.currentCustomerName = customerName;
  }

  static void logoutCustomer() {
    SessionService.currentCustomerId = null;
    SessionService.currentCustomerName = null;
  }

  static void loginWash({required String washId, required String washName}) {
    SessionService.currentWashId = washId;
    SessionService.currentWashName = washName;
  }

  static void logoutWash() {
    SessionService.currentWashId = null;
    SessionService.currentWashName = null;
  }
}
