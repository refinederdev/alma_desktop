class DateHelper {
  /// Adds the specified number of days to the given date.
  DateTime addDays(DateTime date, int days) {
    return date.add(Duration(days: days));
  }
}
