import 'package:flutter/widgets.dart';

/// Abstract interface for managing child vicinities.
///
/// A vicinity manager is responsible for mapping stack position IDs to
/// child vicinities, which are used by the viewport to identify and position
/// children.
abstract class VicinityManager {
  /// Produces a new vicinity for a stack position.
  ///
  /// The [layer] parameter is the z-index of the stack position, and the [id]
  /// parameter is the unique identifier of the stack position.
  ChildVicinity produceVicinity(int layer, String id);
  
  /// Gets the vicinity for a stack position.
  ///
  /// Returns null if the stack position has no vicinity.
  ChildVicinity? getVicinity(String id);
  
  /// Disposes the vicinity manager.
  void dispose();
}

/// A vicinity manager that uses maps to store vicinities.
///
/// This implementation uses a map to store vicinities by ID, and another map
/// to track the highest vicinity in each layer.
class MapVicinityManager implements VicinityManager {
  /// Creates a map vicinity manager.
  MapVicinityManager();

  /// Map of stack position IDs to vicinities.
  final Map<String, ChildVicinity> _vicinities = {};

  /// Map of layers to the highest vicinity in that layer.
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