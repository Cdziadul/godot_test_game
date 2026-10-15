# Third-person terrain starter

A Godot 4 3D starter using only primitive meshes and procedural terrain. One unit represents one meter. No external assets or additional gameplay systems are included.

## Run

Import `project.godot` in Godot 4 (validated with 4.7.2), open it, and press **F5**. The main scene is already configured as `scenes/world/main.tscn`. The Compatibility renderer is selected.

- **WASD:** move relative to camera yaw.
- **Mouse:** orbit the player, with limited vertical rotation.
- **Space:** jump while grounded.
- **V:** toggle third person / first person. First person hides the body and shows primitive hands and forearms. Position and look direction are preserved; movement and jumping work in both views.

Select CameraRig in the player scene to configure the starting view and first-person eye height. Both views share mouse sensitivity and pitch limits. Hands are static primitive meshes; placement and near-terrain clipping need an interactive visual check.
- **Esc:** release the pointer; **left click:** capture it again.

Walking off the terrain eventually returns the player to the spawn point.

## Organization and configuration

The **Rocks** node scatters 300 irregular procedural rocks: 210 small, 75 medium, and 15 large by default (70% / 25% / 5%). Sizes vary within each category, with randomized shape, gray shade, and rotation. Convex collision matches each rock, and placement avoids the spawn area, other rocks, and tree trunks. Player and third-person camera collision include trees and rocks.

Select **Rocks** to configure count, small/medium fractions (large gets the remainder), radius ranges in meters, clearance, color, and seed. Keep small + medium fractions at or below 1. Disable **Randomize Seed** on both Forest and Rocks for repeatable placement. Generation is in `scripts/world/rocks.gd`; crowded settings can place fewer rocks with warnings.

The world includes 220 procedural low-poly pine trees with varied sizes and foliage shades. Trunks have collision; foliage is decorative. Trees are grounded on the actual terrain collision, spaced apart, and excluded from a 14-meter radius around the player's spawn.

Select **Forest** in the main scene to configure tree count, spacing, spawn clearance, edge margin, height, trunk/canopy radius, scale range, and colors. A new layout is generated each launch by default. Disable **Randomize Seed** and set **Forest Seed** for a repeatable layout. Trees generate at runtime; dense settings may place fewer trees and report a warning. Generation lives in `scripts/world/forest.gd`, separately from terrain and player controls.

- `scenes/world/main.tscn`: world composition, sun, procedural sky, spawn position, and control hint.
- `scripts/world/terrain.gd`: runtime mesh and matching triangle collision generation. Select Terrain in the main scene to configure size (default 300 × 300 meters), subdivisions, hill height/frequency, and color. Generation occurs when the game runs.
- `scenes/player/player.tscn`: capsule character, facing marker, collision, and camera hierarchy.
- `scripts/player/player.gd`: Inspector parameters for movement speed, acceleration, jump velocity, gravity, turning, and respawn threshold.
- `scripts/player/orbit_camera.gd`: Inspector parameters for mouse sensitivity, pitch limits, initial pitch, and camera distance. The spring arm avoids terrain clipping and excludes the player collider.
- `tests/smoke_test.gd`: headless gameplay checks.
- `shaders/ground_grid.gdshader`: surface grid that follows the hills, with antialiasing and distant fading. Select Terrain in the main scene to configure **Ground Grid**: enabled, spacing in meters (default 2), line width in meters (default 0.04), and color. These settings apply when the game starts; collision is unaffected.

Change key bindings in **Project → Project Settings → Input Map**. Lighting, camera FOV, collision capsule dimensions, and spawn height are configurable in the scenes. If changing terrain height or spawn location, keep the spawn above the ground. Terrain generation is independent of player controls.

## Command-line validation

From this directory, with your Godot executable substituted for `godot`:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --quit-after 120
godot --headless --path . --script res://tests/smoke_test.gd
```

The smoke test checks landing on generated collision, camera-relative forward movement, jumping and landing, orbit yaw, pitch limiting, and respawn. It exits nonzero on failure.

Headless checks cannot verify rendered appearance, shadows, actual mouse capture, hardware keyboard input, camera feel, or visual clipping. Check those interactively with F5. Only the installed Godot version has been validated; other Godot 4 versions have not been tested.
