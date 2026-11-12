<p align="center">
  <img src="assets/logo.svg" width="88" alt="voxlight logo"/>
</p>

# voxlight

A lightweight, pure Dart 2D visibility polygon, dynamic shadow casting, 2D light evaluation, and grid fog of war engine.

## Features

- **2D Visibility Polygon**: Fast angular sweep raycasting with vertex angular perturbations ($\pm\epsilon$), sorting, and circular clipping.
- **Dynamic 2D Shadows**: Segment-based occluder extraction from boxes/polygons and shadow volume extrusion.
- **2D Lighting**: Point, Spot, and Directional lights with radial falloff, inner/outer spot cone angles, and occlusion ray testing.
- **Fog of War**: Tile-based exploration grid with unexplored, explored, and line-of-sight visible state tracking.
- **Zero Platform Dependencies**: Pure Dart math suitable for WebGL, browser, or native runtime.
