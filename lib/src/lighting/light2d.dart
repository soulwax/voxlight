import 'dart:math' as math;
import '../math/light_vec2.dart';
import '../math/segment2d.dart';

enum Light2DType { point, spot, directional }

class Illumination2D {
  final double r;
  final double g;
  final double b;
  final double intensity;

  const Illumination2D(this.r, this.g, this.b, this.intensity);

  static const Illumination2D zero = Illumination2D(0.0, 0.0, 0.0, 0.0);

  Illumination2D operator +(Illumination2D other) {
    return Illumination2D(
      r + other.r,
      g + other.g,
      b + other.b,
      intensity + other.intensity,
    );
  }
}

/// 2D dynamic point, spot or directional light.
class Light2D {
  final Light2DType type;
  final LightVec2 position;
  final double radius;
  final double innerRadius;
  final double intensity;
  final double r;
  final double g;
  final double b;

  /// Direction vector for spot/directional lights (normalized).
  final LightVec2 direction;

  /// Total cone angle in radians for spot lights (e.g. pi * 0.5 = 90 degrees).
  final double spotAngle;

  /// Inner cone angle where light is 100% full intensity before angular falloff.
  final double innerSpotAngle;

  final bool castsShadows;

  const Light2D({
    this.type = Light2DType.point,
    this.position = LightVec2.zero,
    this.radius = 10.0,
    this.innerRadius = 0.0,
    this.intensity = 1.0,
    this.r = 1.0,
    this.g = 1.0,
    this.b = 1.0,
    this.direction = LightVec2.unitX,
    this.spotAngle = math.pi * 0.5,
    this.innerSpotAngle = math.pi * 0.25,
    this.castsShadows = true,
  });

  /// Evaluates lighting contribution at [target] position, accounting for distance,
  /// cone angles (for spot lights), and optional [occluders] shadow casting.
  Illumination2D evaluate(LightVec2 target, [List<Segment2D>? occluders]) {
    if (intensity <= 0.0 || radius <= 0.0) return Illumination2D.zero;

    if (type == Light2DType.directional) {
      // Directional light: constant across space unless shadowed
      if (castsShadows && occluders != null) {
        final rayDir = -direction;
        for (final seg in occluders) {
          final t = seg.intersectRay(target, rayDir);
          if (t != null && t > 1e-4) return Illumination2D.zero;
        }
      }
      return Illumination2D(r * intensity, g * intensity, b * intensity, intensity);
    }

    // Point or Spot light
    final toTarget = target - position;
    final dist = toTarget.length;
    if (dist > radius || dist < 1e-6) return Illumination2D.zero;

    // Check spot light cone angle
    var angularFactor = 1.0;
    if (type == Light2DType.spot) {
      final toTargetDir = toTarget / dist;
      final dot = direction.normalized.dot(toTargetDir).clamp(-1.0, 1.0);
      final angle = math.acos(dot); // Angle from central axis
      final halfSpot = spotAngle * 0.5;
      final halfInner = innerSpotAngle * 0.5;

      if (angle > halfSpot) return Illumination2D.zero;
      if (angle > halfInner) {
        angularFactor = (1.0 - ((angle - halfInner) / (halfSpot - halfInner))).clamp(0.0, 1.0);
      }
    }

    // Radial distance attenuation: smooth quadratic falloff
    final normalizedDist = (dist - innerRadius) / (radius - innerRadius);
    final radialFactor = (1.0 - normalizedDist.clamp(0.0, 1.0));
    final attenuation = radialFactor * radialFactor * angularFactor;

    if (attenuation <= 1e-5) return Illumination2D.zero;

    // Occlusion raycast test
    if (castsShadows && occluders != null && occluders.isNotEmpty) {
      final rayDir = toTarget / dist;
      for (final seg in occluders) {
        final t = seg.intersectRay(position, rayDir);
        if (t != null && t > 1e-4 && t < dist - 1e-4) {
          // Blocked by occluder -> in shadow!
          return Illumination2D.zero;
        }
      }
    }

    final finalIntensity = intensity * attenuation;
    return Illumination2D(r * finalIntensity, g * finalIntensity, b * finalIntensity, finalIntensity);
  }
}
