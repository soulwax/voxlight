import 'dart:math' as math;
import '../math/light_vec2.dart';
import '../math/segment2d.dart';

enum FogState { unexplored, explored, visible }

/// 2D tile-based Fog of War exploration and line-of-sight tracking.
class FogOfWar {
  final int width;
  final int height;
  final double cellSize;
  final LightVec2 origin;

  final List<FogState> _cells;

  FogOfWar({
    required this.width,
    required this.height,
    this.cellSize = 1.0,
    this.origin = LightVec2.zero,
  }) : _cells = List<FogState>.filled(width * height, FogState.unexplored);

  int get cellCount => _cells.length;

  int _index(int x, int y) => y * width + x;

  bool inBounds(int x, int y) => x >= 0 && x < width && y >= 0 && y < height;

  FogState getTile(int x, int y) {
    if (!inBounds(x, y)) return FogState.unexplored;
    return _cells[_index(x, y)];
  }

  void setTile(int x, int y, FogState state) {
    if (inBounds(x, y)) {
      _cells[_index(x, y)] = state;
    }
  }

  /// Converts world coordinates to grid indices.
  (int, int) worldToGrid(LightVec2 worldPos) {
    final rel = worldPos - origin;
    final gx = (rel.x / cellSize).floor();
    final gy = (rel.y / cellSize).floor();
    return (gx, gy);
  }

  /// Converts grid indices to world center position.
  LightVec2 gridToWorld(int gx, int gy) {
    return origin + LightVec2((gx + 0.5) * cellSize, (gy + 0.5) * cellSize);
  }

  /// Resets currently `visible` tiles to `explored` (e.g. at the start of a turn or frame).
  void clearVisibility() {
    for (int i = 0; i < _cells.length; i++) {
      if (_cells[i] == FogState.visible) {
        _cells[i] = FogState.explored;
      }
    }
  }

  /// Reveals a circular area around [center] up to [radius].
  /// If [occluders] are provided, tests line-of-sight raycasts to avoid revealing behind walls.
  void reveal(LightVec2 center, double radius, [List<Segment2D>? occluders]) {
    final (cgx, cgy) = worldToGrid(center);
    final gridRadius = (radius / cellSize).ceil();
    final radiusSq = radius * radius;

    for (int dy = -gridRadius; dy <= gridRadius; dy++) {
      for (int dx = -gridRadius; dx <= gridRadius; dx++) {
        final gx = cgx + dx;
        final gy = cgy + dy;
        if (!inBounds(gx, gy)) continue;

        final cellWorld = gridToWorld(gx, gy);
        final distSq = center.distanceSquared(cellWorld);
        if (distSq > radiusSq) continue;

        // Line-of-sight test against occluders
        bool blocked = false;
        if (occluders != null && occluders.isNotEmpty && distSq > 1e-4) {
          final rayDist = math.sqrt(distSq);
          final rayDir = (cellWorld - center) / rayDist;

          for (final seg in occluders) {
            final t = seg.intersectRay(center, rayDir);
            if (t != null && t > 1e-3 && t < rayDist - cellSize * 0.5) {
              blocked = true;
              break;
            }
          }
        }

        if (!blocked) {
          _cells[_index(gx, gy)] = FogState.visible;
        }
      }
    }
  }

  bool isVisible(LightVec2 worldPos) {
    final (gx, gy) = worldToGrid(worldPos);
    return getTile(gx, gy) == FogState.visible;
  }

  bool isExplored(LightVec2 worldPos) {
    final (gx, gy) = worldToGrid(worldPos);
    final s = getTile(gx, gy);
    return s == FogState.explored || s == FogState.visible;
  }
}
