import '../math/light_vec2.dart';
import '../math/segment2d.dart';

/// Utilities for generating 2D shadow occluders and shadow extrusion volumes.
class ShadowCaster2D {
  /// Segments defining the occluding boundaries of this caster.
  final List<Segment2D> segments;

  const ShadowCaster2D(this.segments);

  /// Creates a shadow caster from an axis-aligned box.
  factory ShadowCaster2D.fromBox(LightVec2 center, LightVec2 halfExtents) {
    final minX = center.x - halfExtents.x;
    final maxX = center.x + halfExtents.x;
    final minY = center.y - halfExtents.y;
    final maxY = center.y + halfExtents.y;

    final p0 = LightVec2(minX, minY);
    final p1 = LightVec2(maxX, minY);
    final p2 = LightVec2(maxX, maxY);
    final p3 = LightVec2(minX, maxY);

    return ShadowCaster2D([
      Segment2D(p0, p1),
      Segment2D(p1, p2),
      Segment2D(p2, p3),
      Segment2D(p3, p0),
    ]);
  }

  /// Creates a shadow caster from a closed polygon.
  factory ShadowCaster2D.fromPolygon(List<LightVec2> vertices) {
    if (vertices.length < 3) return const ShadowCaster2D([]);
    final segs = <Segment2D>[];
    for (int i = 0; i < vertices.length; i++) {
      segs.add(Segment2D(vertices[i], vertices[(i + 1) % vertices.length]));
    }
    return ShadowCaster2D(segs);
  }

  /// Extrudes shadow volume quads for all segments facing away from [lightSource].
  ///
  /// Each quad is a list of 4 vertices: [a, b, bExtruded, aExtruded].
  List<List<LightVec2>> extrudeShadows(LightVec2 lightSource, {double shadowDistance = 1000.0}) {
    final quads = <List<LightVec2>>[];

    for (final seg in segments) {
      final mid = (seg.a + seg.b) * 0.5;
      final toMid = mid - lightSource;

      // Only extrude segments where light shines on front face
      final normal = seg.normal;
      if (normal.dot(toMid) <= 0.0) {
        final dirA = (seg.a - lightSource).normalized;
        final dirB = (seg.b - lightSource).normalized;

        final aExt = seg.a + dirA * shadowDistance;
        final bExt = seg.b + dirB * shadowDistance;

        quads.add([seg.a, seg.b, bExt, aExt]);
      }
    }

    return quads;
  }
}
