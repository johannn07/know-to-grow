// Leans a plant in the wind: the top of the image moves, the base stays put.
//
// It moves the image's corners, not its pixels. The plant art is cropped tight
// to its edges, so shifting pixels inside the image would cut leaves off at
// the sides; moving the corners never clips. It is also the cheapest sway there
// is — four vertices a frame and no extra work per pixel — which is what a
// low-end phone needs.
shader_type canvas_item;

// How far the top of the image travels either way, in the image's own pixels.
uniform float sway_px = 12.0;
// Cycles a second of the main sway, before the gusts are added.
uniform float speed = 0.9;
// Offset into the cycle, so two plants on one screen do not move in step.
uniform float phase = 0.0;

void vertex() {
	float t = TIME * speed * TAU + phase;
	// A slow sway with a faster, weaker gust on top reads as wind rather than
	// as a metronome.
	float gust = sin(t) * 0.75 + sin(t * 2.3 + 1.1) * 0.25;
	VERTEX.x += gust * sway_px * (1.0 - UV.y);
}
