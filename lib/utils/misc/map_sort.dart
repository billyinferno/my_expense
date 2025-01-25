enum MapSortType {
  ascending,
  descending,
}

Map<K, V> sortedMap<K, V>({
  required Map<K, V> data,
  MapSortType type = MapSortType.ascending
}) {
  Map<K, V> sorted = {};
  
  List<K> sortedKeys = data.keys.toList()..sort();
  
  // check sort type
  if (type == MapSortType.descending) {
    sortedKeys = sortedKeys.reversed.toList();
  }

  // loop thru the sorted keys, and create the sorted map
  for (var keys in sortedKeys) {
    sorted[keys] = data[keys] as V;
  }

  // return sorted map
  return sorted;
}