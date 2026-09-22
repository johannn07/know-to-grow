// Leans a plant in the wind and lets it breathe: the top of the image moves,
// the base stays put.
//
// It moves the image's corners, not its pixels. The plant art is cropped tight
// to its edges, so shifting pixels inside the image would cut leaves off at
// the sides; moving the corners never clips. It is also the cheapest sway there
// is — four vertices a frame and no extra work per pixel — which is what a
// low-end phone needs.
shader_type canvas_item;

#include "res://shaders/wind_sway.gdshaderinc"

void vertex() {
	VERTEX += alive_offset(TIME, UV);
}
