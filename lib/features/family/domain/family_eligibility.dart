enum FamilyEligibility { unresolved, child, eligible }

abstract final class FamilyEligibilityPolicy {
  static const eligibilityAge = 13;

  static DateTime localDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime? parseLocalDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final parsed = DateTime(year, month, day);
    return parsed.year == year && parsed.month == month && parsed.day == day
        ? parsed
        : null;
  }

  static String formatLocalDate(DateTime value) {
    final date = localDate(value);
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime eligibilityDateFor(DateTime birthDate) {
    final date = localDate(birthDate);
    final targetYear = date.year + eligibilityAge;
    if (date.month == DateTime.february &&
        date.day == 29 &&
        !_isLeapYear(targetYear)) {
      return DateTime(targetYear, DateTime.march, 1);
    }
    return DateTime(targetYear, date.month, date.day);
  }

  static bool isEligible(DateTime eligibilityDate, DateTime today) =>
      !localDate(eligibilityDate).isAfter(localDate(today));

  static bool _isLeapYear(int year) =>
      year % 400 == 0 || (year % 4 == 0 && year % 100 != 0);
}
