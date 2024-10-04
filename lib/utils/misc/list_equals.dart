import 'package:flutter/foundation.dart';

bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) {
    return b == null;
  }
  if (b == null) {
    return false;
  }
  if (a.length != b.length) {
    return false;
  }

  if (identical(a, b)) {
    return true;
  }
  
  for (int index = 0; index < a.length; index += 1) {
    // check if this a map? if map then just compare the length
    if (a[index] is Map && b[index] is Map) {
      if (!mapEquals(a[index] as Map, b[index] as Map)) {
        return false;
      }
    }
    else {
      if (a[index] != b[index]) {
        return false;
      }
    }
  }
  return true;
}