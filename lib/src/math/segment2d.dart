import 'light_vec2.dart';

/// 2D line segment representing an occluding wall or shadow edge.
class Segment2D {
  final LightVec2 a;
  final LightVec2 b;

  const Segment2D(this.a, this.b);

  double get length => a.distance(b);
  double get lengthSquared => a.distanceSquared(b);

  LightVec2 get direction => (b - a).normalized;

  /// Normal pointing perpendicular to (b - a) rotated 90 degrees CCW.
  LightVec2 get normal {
    final d = b - a;
    final len = d.length;
    if (len < 1e-12) return LightVec2.zero;
    return LightVec2(-d.y / len, d.x / len);
  }

  /// Calculates ray intersection with this segment.
  /// Ray is defined as [rayOrigin] + t * [rayDirection].
  /// Returns t (distance along ray) if intersecting segment [a, b], or null if no hit.
  double? intersectRay(LightVec2 rayOrigin, LightVec2 rayDirection) {
    final v1 = rayOrigin - a;
    final v2 = b - a;
    final v3 = LightVec2(-rayDirection.y, rayDirection.x);

    final dot = v2.dot(v3);
    if (dot.abs() < 1e-12) return null; // Parallel

    final t1 = v2.cross(v1) / dot;
    final t2 = v1.dot(v3) / dot;

    if (t1 >= 0.0 && t2 >= 0.0 && t2 <= 1.0) {
      return t1;
    }
    return null;
  }

  /// Returns closest point on this segment to [point].
  LightVec2 closestPoint(LightVec2 point) {
    final ab = b - a;
    final abLenSq = ab.lengthSquared;
    if (abLenSq < 1e-12) return a;

    final ap = point - a;
    final t = (ap.dot(ab) / abLenSq).clamp(0.0, 1.0);
    return a + ab * t;
  }

  /// Distance from [point] to this segment.
  double distanceToPoint(LightVec2 point) => point.distance(closestPoint(point));

  @override
  String toString() => 'Segment2D($a -> $b)';
}
