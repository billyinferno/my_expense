extension CustomDateExtestion on DateTime {
  bool isSameDate({
    required DateTime date
  }) {
    // check if year same or not?
    if (year == date.year) {
      // same, now check if month is the same or not?
      if (month == date.month) {
        // same month, now check if the day is the same or not?
        if (day == date.day) {
          // same day, so this is same day
          return true;
        }
      }
    }
    return false;
  }

  bool isWithin({
    required DateTime from,
    required DateTime to
  }) {
    if ((isAtSameMomentAs(from) || isAfter(from)) && (isAtSameMomentAs(to) || isBefore(to))) {
      return true;
    }
    return false;
  }
}