import 'package:flutter/widgets.dart';

abstract class VicinityManager {
  ChildVicinity produceVicinity(int layer, String id);
  ChildVicinity? getVicinity(String id);
  void dispose();
}

class MapVicinityManager implements VicinityManager {
  MapVicinityManager();

  /// The first axis is [layer] and the second axis is [id] of the child.
  final Map<String, ChildVicinity> _vicinities = {};

  /// The highest [ChildVicinity] in the [layer] axis.
  final Map<int, ChildVicinity> _highestVicinities = {};

  @override
  void dispose() {
    _vicinities.clear();
    _highestVicinities.clear();
  }

  @override
  ChildVicinity produceVicinity(int layer, String id) {
    final vicinity = _highestVicinities[layer];
    final newVicinity = ChildVicinity(
      xIndex: (vicinity?.xIndex ?? 0) + 1,
      yIndex: layer,
    );
    _highestVicinities[layer] = newVicinity;
    _vicinities[id] = newVicinity;
    return newVicinity;
  }

  @override
  ChildVicinity? getVicinity(String id) {
    return _vicinities[id];
  }
}
