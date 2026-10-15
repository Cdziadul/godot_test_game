shader_type spatial;

uniform vec4 ground_color : source_color = vec4(0.27, 0.43, 0.24, 1.0);
uniform vec4 grid_color : source_color = vec4(0.12, 0.20, 0.10, 1.0);
uniform bool grid_enabled = true;
uniform float grid_spacing : hint_range(0.1, 50.0) = 2.0;
uniform float line_width : hint_range(0.005, 0.5) = 0.04;

varying vec2 ground_position;

void vertex() {
	// Mesh coordinates keep the grid attached to the terrain, without UVs.
	ground_position = VERTEX.xz;
}

void fragment() {
	float spacing = max(grid_spacing, 0.1);
	vec2 grid_uv = ground_position / spacing;
	vec2 footprint = max(fwidth(grid_uv), vec2(0.00001));
	vec2 distance_to_line = abs(fract(grid_uv + 0.5) - 0.5);
	float half_width = min(line_width / spacing, 0.5) * 0.5;
	vec2 lines = vec2(1.0) - smoothstep(
		vec2(half_width) - footprint * 0.5,
		vec2(half_width) + footprint * 0.5,
		distance_to_line
	);
	// Fade lines as cells approach pixel size to reduce distant shimmer.
	vec2 fade = vec2(1.0) - smoothstep(vec2(0.1), vec2(0.5), footprint);
	float grid = grid_enabled ? max(lines.x * fade.x, lines.y * fade.y) : 0.0;
	ALBEDO = mix(ground_color.rgb, grid_color.rgb, grid);
	ROUGHNESS = 1.0;
}
