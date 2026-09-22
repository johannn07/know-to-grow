// The wind lean, shared by every shader that draws a plant, so swapping one for
// another mid-sway does not make the plant jump. See wind_sway.gdshader.

// How far the top of the image travels either way, in the image's own pixels.
uniform float sway_px = 12.0;
// Cycles a second of the main sway, before the gusts are added.
uniform float speed = 0.9;
// Offset into the cycle, so two plants on one screen do not move in step.
uniform float phase = 0.0;

float wind_offset(float time, vec2 uv) {
	float t = time * speed * TAU + phase;
	// A slow sway with a faster, weaker gust on top reads as wind rather than
	// as a metronome.
	float gust = sin(t) * 0.75 + sin(t * 2.3 + 1.1) * 0.25;
	return gust * sway_px * (1.0 - uv.y);
}
