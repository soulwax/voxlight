import 'dart:math' as math;
import 'package:test/test.dart';
import 'package:voxlight/voxlight.dart';

void main() {
  group('voxlight - LightVec2 & Segment2D', () {
    test('LightVec2 arithmetic and rotation', () {
      const v1 = LightVec2(3.0, 4.0);
      expect(v1.length, equals(5.0));
      expect(v1.normalized.length, closeTo(1.0, 1e-6));

      final v2 = const LightVec2(1.0, 0.0).rotate(math.pi * 0.5);
      expect(v2.x, closeTo(0.0, 1e-6));
      expect(v2.y, closeTo(1.0, 1e-6));
    });

    test('Segment2D ray intersection and distance to point', () {
      const seg = Segment2D(LightVec2(-2.0, 5.0), LightVec2(2.0, 5.0));
      final t = seg.intersectRay(LightVec2.zero, const LightVec2(0.0, 1.0));
      expect(t, isNotNull);
      expect(t!, closeTo(5.0, 1e-6));

      // Ray pointing in opposite direction should not hit
      final miss = seg.intersectRay(LightVec2.zero, const LightVec2(0.0, -1.0));
      expect(miss, isNull);

      // Distance to point
      expect(seg.distanceToPoint(const LightVec2(0.0, 2.0)), closeTo(3.0, 1e-6));
    });
  });

  group('voxlight - VisibilityPolygon', () {
    test('computes visibility polygon with wall occlusion', () {
      const origin = LightVec2(0.0, 0.0);
      // Wall between y=5, x from -2 to 2
      final wall = const Segment2D(LightVec2(-2.0, 5.0), LightVec2(2.0, 5.0));

      final poly = VisibilityPolygon.compute(
        origin: origin,
        segments: [wall],
        maxRadius: 10.0,
      );

      expect(poly.vertices.length, greaterThanOrEqualTo(8));
      // Point in front of wall is visible
      expect(poly.contains(const LightVec2(0.0, 2.0)), isTrue);
      // Point behind wall is in shadow / occluded
      expect(poly.contains(const LightVec2(0.0, 8.0)), isFalse);
    });
  });

  group('voxlight - ShadowCaster2D', () {
    test('fromBox creates 4 segments and extrudes shadow quads', () {
      final caster = ShadowCaster2D.fromBox(const LightVec2(0.0, 5.0), const LightVec2(1.0, 1.0));
      expect(caster.segments.length, equals(4));

      final shadows = caster.extrudeShadows(LightVec2.zero, shadowDistance: 50.0);
      expect(shadows.isNotEmpty, isTrue);
      for (final quad in shadows) {
        expect(quad.length, equals(4));
      }
    });
  });

  group('voxlight - Light2D', () {
    test('Point light radial falloff and shadow obstruction', () {
      const light = Light2D(
        type: Light2DType.point,
        position: LightVec2.zero,
        radius: 10.0,
        intensity: 2.0,
        r: 1.0,
        g: 0.5,
        b: 0.2,
      );

      // Center illumination
      final illumClose = light.evaluate(const LightVec2(1.0, 0.0));
      expect(illumClose.intensity, greaterThan(1.0));

      // Out of range
      final illumFar = light.evaluate(const LightVec2(15.0, 0.0));
      expect(illumFar.intensity, equals(0.0));

      // With occluder
      const wall = Segment2D(LightVec2(-2.0, 3.0), LightVec2(2.0, 3.0));
      final blocked = light.evaluate(const LightVec2(0.0, 6.0), [wall]);
      expect(blocked.intensity, equals(0.0));
    });

    test('Spot light cone angle restriction', () {
      const spot = Light2D(
        type: Light2DType.spot,
        position: LightVec2.zero,
        direction: LightVec2(0.0, 1.0), // pointing along +Y
        radius: 10.0,
        spotAngle: math.pi * 0.5, // 90 degree cone
        intensity: 1.0,
      );

      // In cone (+Y)
      final inside = spot.evaluate(const LightVec2(0.0, 5.0));
      expect(inside.intensity, greaterThan(0.0));

      // Outside cone (-Y or +X)
      final outside = spot.evaluate(const LightVec2(5.0, 0.0));
      expect(outside.intensity, equals(0.0));
    });
  });

  group('voxlight - FogOfWar', () {
    test('reveals tiles and respects line of sight', () {
      final fog = FogOfWar(width: 20, height: 20, cellSize: 1.0, origin: const LightVec2(-10.0, -10.0));

      // Initially all unexplored
      expect(fog.isExplored(LightVec2.zero), isFalse);

      // Wall at y = 2
      const wall = Segment2D(LightVec2(-3.0, 2.0), LightVec2(3.0, 2.0));

      fog.reveal(LightVec2.zero, 5.0, [wall]);

      // Point in front of wall is visible
      expect(fog.isVisible(const LightVec2(0.0, 1.0)), isTrue);
      expect(fog.isExplored(const LightVec2(0.0, 1.0)), isTrue);

      // Point behind wall is not visible
      expect(fog.isVisible(const LightVec2(0.0, 4.0)), isFalse);

      // Clear visibility sets visible to explored
      fog.clearVisibility();
      expect(fog.isVisible(const LightVec2(0.0, 1.0)), isFalse);
      expect(fog.isExplored(const LightVec2(0.0, 1.0)), isTrue);
    });
  });
}
