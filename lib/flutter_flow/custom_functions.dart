double getProgressBarValue(
  double? score,
  double? milestoneTarget,
) {
  if (score == null) {
    return 0.0;
  }

  // Uses the passed maximum cap, or defaults to 500.0 if empty or zero —
  // a zero target would otherwise divide by zero and produce NaN, which
  // clamp() does not catch (NaN comparisons are always false).
  final double target =
      (milestoneTarget == null || milestoneTarget == 0.0)
          ? 500.0
          : milestoneTarget;

  return (score / target).clamp(0.0, 1.0);
}

bool isBusinessOpen(
  String? openingTime,
  String? closingTime,
) {
// If either time is missing, treat the business as closed.
  if (openingTime == null ||
      closingTime == null ||
      openingTime.isEmpty ||
      closingTime.isEmpty) {
    return false;
  }

  // Converts a 12-hour string like "08:00 AM" into minutes since midnight.
  // Returns null if the string cannot be parsed.
  int? toMinutes(String raw) {
    final cleaned = raw.trim().toUpperCase();

    // Split the time portion from the AM/PM marker.
    final parts = cleaned.split(' ');
    if (parts.length != 2) return null;

    final timePart = parts[0]; // "08:00"
    final meridiem = parts[1]; // "AM" or "PM"

    final hm = timePart.split(':');
    if (hm.length != 2) return null;

    int? hour = int.tryParse(hm[0]);
    int? minute = int.tryParse(hm[1]);
    if (hour == null || minute == null) return null;
    if (hour < 1 || hour > 12 || minute < 0 || minute > 59) return null;

    // Convert to 24-hour clock.
    if (meridiem == 'PM' && hour != 12) {
      hour += 12;
    } else if (meridiem == 'AM' && hour == 12) {
      hour = 0; // 12:00 AM is midnight
    }

    return hour * 60 + minute;
  }

  final openMin = toMinutes(openingTime);
  final closeMin = toMinutes(closingTime);

  // If parsing failed on either value, fail safe to closed.
  if (openMin == null || closeMin == null) return false;

  // Current local time in minutes since midnight.
  final now = DateTime.now();
  final nowMin = now.hour * 60 + now.minute;

  if (openMin == closeMin) {
    // Treat identical open/close as open 24 hours.
    return true;
  } else if (closeMin > openMin) {
    // Normal same-day hours, e.g. 08:00 AM to 10:00 PM.
    return nowMin >= openMin && nowMin < closeMin;
  } else {
    // Overnight hours that cross midnight, e.g. 06:00 PM to 02:00 AM.
    return nowMin >= openMin || nowMin < closeMin;
  }
}

DateTime calculateExpiration(int durationHours) {
  return DateTime.now().add(Duration(hours: durationHours));
}
