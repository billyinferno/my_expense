extension CustomDateExtestion on DateTime {
  bool isSameDate({
    required DateTime date
  }) {
    // check if year same or not?
    if (toLocal().year == date.toLocal().year) {
      // same, now check if month is the same or not?
      if (toLocal().month == date.toLocal().month) {
        // same month, now check if the day is the same or not?
        if (toLocal().day == date.toLocal().day) {
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
    if (
      (toLocal().isAtSameMomentAs(from.toLocal()) || toLocal().isAfter(from.toLocal())) &&
      (toLocal().isAtSameMomentAs(to.toLocal()) || toLocal().isBefore(to.toLocal()))
    ) {
      return true;
    }
    return false;
  }
}