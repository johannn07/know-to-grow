// The plant growing in: revealed from the soil upward, with a warm glowing
// front and a few sparkles riding it.
//
// Only on the hub's plant, and only for the second or so it is growing; the
// hub swaps back to the plain sway afterwards, so this costs nothing the rest
// of the time. It sways exactly as wind_sway does meanwhile.
shader_type canvas_item;

#include "res://shaders/wind_sway.gdshaderinc"

// 0 is nothing showing, 1 the whole plant. Animated by the hub.
uniform float reveal : hint_range(0.0, 1.0) = 1.0;
// The glow along the growing front.
uniform vec4 edge_color : source_color = vec4(1.0, 0.94, 0.6, 1.0);
// How tall the glowing band is, as a fraction of the image.
uniform float edge_width : hint_range(0.01, 0.3) = 0.08;

varying vec4 tint;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	VERTEX.x += wind_offset(TIME, UV);
	tint = COLOR;
}

void fragment() {
	vec4 plant = texture(TEXTURE, UV);
	float height = 1.0 - UV.y;
	// The front runs from just under the base to just over the top, so 0 and 1
	// really are nothing and everything. A small wave keeps it from reading as
	// a ruler-straight wipe.
	float front = mix(-edge_width, 1.0 + edge_width, reveal)
		+ sin(UV.x * 18.0 + TIME * 6.0) * 0.012;
	float behind = front - height;
	float shown = smoothstep(0.0, 0.012, behind);
	float glow = shown * (1.0 - smoothstep(0.0, edge_width, behind));

	// Sparkles: a sparse grid of cells, a few of which twinkle, only in the band.
	vec2 cell = floor(UV * vec2(22.0, 36.0));
	float seed = hash(cell);
	float twinkle = step(0.9, seed) * (0.5 + 0.5 * sin(TIME * 14.0 + seed * 40.0));
	float sparkle = twinkle * glow;

	vec3 rgb = mix(plant.rgb, edge_color.rgb, glow * 0.75) + vec3(sparkle);
	float alpha = max(plant.a * shown, sparkle * 0.9);
	COLOR = vec4(rgb, alpha) * tint;
}
