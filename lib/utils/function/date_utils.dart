bool isSameDay(DateTime dt1, DateTime dt2) {
  // check if year same or not?
  if (dt1.year == dt2.year) {
    // same, now check if month is the same or not?
    if (dt1.month == dt2.month) {
      // same month, now check if the day is the same or not?
      if (dt1.day == dt2.day) {
        // same day, so this is same day
        return true;
      }
    }
  }
  return false;
}

bool isWithin(DateTime date, DateTime from, DateTime to) {
  if ((date.isAtSameMomentAs(from) || date.isAfter(from)) && (date.isAtSameMomentAs(to) || date.isBefore(to))) {
    return true;
  }
  return false;
}