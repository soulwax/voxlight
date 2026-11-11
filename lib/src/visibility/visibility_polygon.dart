import 'dart:math' as math;
import '../math/light_vec2.dart';
import '../math/segment2d.dart';

class _RayHit {
  final double angle;
  final LightVec2 point;
  final double distance;

  const _RayHit(this.angle, this.point, this.distance);
}

/// Computes 2D visibility / field-of-view polygons from a point source using angular ray sweeping.
class VisibilityPolygon {
  /// Source position of the light or eye.
  final LightVec2 origin;

  /// Ordered boundary vertices of the visibility polygon.
  final List<LightVec2> vertices;

  /// Max radius of vision / illumination.
  final double maxRadius;

  const VisibilityPolygon({
    required this.origin,
    required this.vertices,
    required this.maxRadius,
  });

  /// Computes the 2D visibility polygon from [origin] given occluding [segments].
  ///
  /// If [maxRadius] is provided, visibility is clamped within this distance.
  /// If [bounds] is provided, bounding segments are added around the area.
  static VisibilityPolygon compute({
    required LightVec2 origin,
    required List<Segment2D> segments,
    double maxRadius = 100.0,
    int boundarySegments = 16,
  }) {
    final allSegments = <Segment2D>[...segments];

    // Add circular boundary segments to constrain open space
    final boundaryPts = <LightVec2>[];
    for (int i = 0; i < boundarySegments; i++) {
      final a = (i / boundarySegments) * 2.0 * math.pi;
      boundaryPts.add(origin + LightVec2(math.cos(a), math.sin(a)) * maxRadius);
    }
    for (int i = 0; i < boundarySegments; i++) {
      allSegments.add(Segment2D(boundaryPts[i], boundaryPts[(i + 1) % boundarySegments]));
    }

    // Collect all angles to test: vertex endpoints +/- epsilon
    final angles = <double>{};
    const epsilon = 1e-4;

    for (final seg in allSegments) {
      for (final pt in [seg.a, seg.b]) {
        final toPt = pt - origin;
        if (toPt.lengthSquared > 1e-9) {
          final baseAngle = toPt.angle;
          angles.add(baseAngle - epsilon);
          angles.add(baseAngle);
          angles.add(baseAngle + epsilon);
        }
      }
    }

    // Cast rays for each angle and find closest segment hit
    final hits = <_RayHit>[];
    for (final angle in angles) {
      final rayDir = LightVec2(math.cos(angle), math.sin(angle));
      double closestT = maxRadius;
      LightVec2 closestHit = origin + rayDir * maxRadius;

      for (final seg in allSegments) {
        final t = seg.intersectRay(origin, rayDir);
        if (t != null && t > 1e-5 && t < closestT) {
          closestT = t;
          closestHit = origin + rayDir * t;
        }
      }

      hits.add(_RayHit(angle, closestHit, closestT));
    }

    // Sort hits counter-clockwise by angle
    hits.sort((a, b) => a.angle.compareTo(b.angle));

    // Remove near-duplicate consecutive vertices
    final polygon = <LightVec2>[];
    for (final hit in hits) {
      if (polygon.isEmpty || polygon.last.distanceSquared(hit.point) > 1e-4) {
        polygon.add(hit.point);
      }
    }

    return VisibilityPolygon(
      origin: origin,
      vertices: polygon,
      maxRadius: maxRadius,
    );
  }

  /// Tests if [point] is inside this visibility polygon (point-in-polygon ray casting).
  bool contains(LightVec2 point) {
    if (point.distanceSquared(origin) > maxRadius * maxRadius) return false;
    if (vertices.length < 3) return false;

    bool inside = false;
    int j = vertices.length - 1;
    for (int i = 0; i < vertices.length; i++) {
      final vi = vertices[i];
      final vj = vertices[j];

      if ((vi.y > point.y) != (vj.y > point.y) &&
          point.x < (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y) + vi.x) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }
}
