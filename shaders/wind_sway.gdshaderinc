// The wind lean and the breath, shared by every shader that draws a plant or a
// character, so swapping one for another mid-sway does not make it jump. See
// wind_sway.gdshader.

// How far the top of the image travels either way, in the image's own pixels.
uniform float sway_px = 12.0;
// Cycles a second of the main sway, before the gusts are added.
uniform float speed = 0.9;
// Offset into the cycle, so two plants on one screen do not move in step.
uniform float phase = 0.0;
// How far the top rises on each breath, in the image's own pixels. The sides
// draw in by half as much, so it stretches up rather than just growing.
uniform float breath_px = 7.0;
// Breaths a second. Slow, so it reads as alive rather than as bouncing.
uniform float breath_speed = 0.33;

float wind_offset(float time, vec2 uv) {
	float t = time * speed * TAU + phase;
	// A slow sway with a faster, weaker gust on top reads as wind rather than
	// as a metronome.
	float gust = sin(t) * 0.75 + sin(t * 2.3 + 1.1) * 0.25;
	return gust * sway_px * (1.0 - uv.y);
}

// Squash and stretch about the base: the top rises and the sides pull in, then
// it settles back a little wider. The base itself never moves.
vec2 breath_offset(float time, vec2 uv) {
	float breath = sin(time * breath_speed * TAU + phase * 0.7);
	float rise = breath * breath_px * (1.0 - uv.y);
	float pull = -breath * breath_px * 0.5 * (uv.x * 2.0 - 1.0);
	return vec2(pull, -rise);
}

// Everything a living thing does on its own: the wind lean plus the breath.
vec2 alive_offset(float time, vec2 uv) {
	return vec2(wind_offset(time, uv), 0.0) + breath_offset(time, uv);
}
