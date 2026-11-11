import 'dart:math' as math;

/// 2D vector for 2D lighting, ray sweeping, and visibility polygon calculations.
class LightVec2 {
  final double x;
  final double y;

  const LightVec2(this.x, this.y);

  static const LightVec2 zero = LightVec2(0.0, 0.0);
  static const LightVec2 unitX = LightVec2(1.0, 0.0);
  static const LightVec2 unitY = LightVec2(0.0, 1.0);

  LightVec2 operator +(LightVec2 other) => LightVec2(x + other.x, y + other.y);
  LightVec2 operator -(LightVec2 other) => LightVec2(x - other.x, y - other.y);
  LightVec2 operator *(double scalar) => LightVec2(x * scalar, y * scalar);
  LightVec2 operator /(double scalar) => LightVec2(x / scalar, y / scalar);
  LightVec2 operator -() => LightVec2(-x, -y);

  double dot(LightVec2 other) => x * other.x + y * other.y;
  double cross(LightVec2 other) => x * other.y - y * other.x;

  double get lengthSquared => x * x + y * y;
  double get length => math.sqrt(lengthSquared);

  LightVec2 get normalized {
    final len = length;
    if (len < 1e-12) return LightVec2.zero;
    return LightVec2(x / len, y / len);
  }

  double distance(LightVec2 other) => (this - other).length;
  double distanceSquared(LightVec2 other) => (this - other).lengthSquared;

  /// Returns the angle in radians in range [-pi, pi] using atan2.
  double get angle => math.atan2(y, x);

  /// Rotates vector by [radians].
  LightVec2 rotate(double radians) {
    final c = math.cos(radians);
    final s = math.sin(radians);
    return LightVec2(x * c - y * s, x * s + y * c);
  }

  static LightVec2 lerp(LightVec2 a, LightVec2 b, double t) {
    return LightVec2(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LightVec2 &&
          (x - other.x).abs() < 1e-6 &&
          (y - other.y).abs() < 1e-6;

  @override
  int get hashCode => Object.hash((x * 1000).round(), (y * 1000).round());

  @override
  String toString() => 'LightVec2(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';
}
