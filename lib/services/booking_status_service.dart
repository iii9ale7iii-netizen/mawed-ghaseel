import 'package:flutter/material.dart';

class BookingStatusService {
  BookingStatusService._();

  static const pending = 'بانتظار الموافقة';
  static const accepted = 'مقبول';
  static const rejected = 'مرفوض';

  static final Set<String> _pendingValues = {
    pending,
    'ط¨ط§ظ†طھط¸ط§ط± ط§ظ„ظ…ظˆط§ظپظ‚ط©',
    'ط·آ¨ط·آ§ط¸â€ ط·ع¾ط·آ¸ط·آ§ط·آ± ط·آ§ط¸â€‍ط¸â€¦ط¸ث†ط·آ§ط¸ظ¾ط¸â€ڑط·آ©',
    'ط·آ·ط¢آ¨ط·آ·ط¢آ§ط·آ¸أ¢â‚¬آ ط·آ·ط¹آ¾ط·آ·ط¢آ¸ط·آ·ط¢آ§ط·آ·ط¢آ± ط·آ·ط¢آ§ط·آ¸أ¢â‚¬â€چط·آ¸أ¢â‚¬آ¦ط·آ¸ط«â€ ط·آ·ط¢آ§ط·آ¸ط¸آ¾ط·آ¸أ¢â‚¬ع‘ط·آ·ط¢آ©',
  };

  static final Set<String> _acceptedValues = {
    accepted,
    'ظ…ظ‚ط¨ظˆظ„',
    'ط¸â€¦ط¸â€ڑط·آ¨ط¸ث†ط¸â€‍',
    'ط·آ¸أ¢â‚¬آ¦ط·آ¸أ¢â‚¬ع‘ط·آ·ط¢آ¨ط·آ¸ط«â€ ط·آ¸أ¢â‚¬â€چ',
  };

  static final Set<String> _rejectedValues = {
    rejected,
    'ظ…ط±ظپظˆط¶',
    'ط¸â€¦ط·آ±ط¸ظ¾ط¸ث†ط·آ¶',
    'ط·آ¸أ¢â‚¬آ¦ط·آ·ط¢آ±ط·آ¸ط¸آ¾ط·آ¸ط«â€ ط·آ·ط¢آ¶',
  };

  static String normalize(String status) {
    if (_pendingValues.contains(status)) return pending;
    if (_acceptedValues.contains(status)) return accepted;
    if (_rejectedValues.contains(status)) return rejected;
    return pending;
  }

  static bool isPending(String status) => normalize(status) == pending;
  static bool isAccepted(String status) => normalize(status) == accepted;
  static bool isRejected(String status) => normalize(status) == rejected;

  static String label(String status) => normalize(status);

  static Color color(String status) {
    if (isAccepted(status)) return Colors.green;
    if (isRejected(status)) return Colors.red;
    return Colors.orange;
  }
}
