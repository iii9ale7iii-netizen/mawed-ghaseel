class SessionService {
  static String? currentCustomerId;
  static String? currentCustomerName;

  static String? currentWashId;
  static String? currentWashName;

  static void clear() {
    currentCustomerId = null;
    currentCustomerName = null;
    currentWashId = null;
    currentWashName = null;
  }
}
