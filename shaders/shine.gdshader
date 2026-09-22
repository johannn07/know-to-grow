// A glint that sweeps across something earned every few seconds, so earned
// badges and stars look precious next to the matte locked ones.
//
// Only the band of light moves; the art underneath is untouched and keeps its
// own alpha, so the glint never spills outside the shape. Each copy starts its
// sweep a little later the further right and down it sits on screen, so a row
// of stars catches the light one after another rather than all at once.
//
// By default the band crosses the image's own texture. A themed button is not
// one image — its plate is a stretched nine-patch and its words come from the
// font — so for one of those set local_space and box_size, and the band crosses
// the node's own rect instead, plate and text together.
shader_type canvas_item;

// The colour of the light.
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 0.92, 1.0);
// How strongly the band lightens the art, 0 to 1.
uniform float strength : hint_range(0.0, 1.0) = 0.6;
// Width of the band, as a fraction of the image.
uniform float width : hint_range(0.02, 0.5) = 0.16;
// Seconds from one glint to the next.
uniform float period = 3.5;
// Seconds the band takes to cross.
uniform float sweep = 0.7;
// How far the band leans: 0 is upright, 1 is 45 degrees.
uniform float slant = 0.6;
// Seconds of delay per screen pixel, which is what staggers a row.
uniform float stagger = 0.0006;
// Sweep across the node's rect rather than its texture. See the note above.
uniform bool local_space = false;
// The node's size in its own pixels, kept up to date by its script.
uniform vec2 box_size = vec2(1.0, 1.0);

varying float delay;
varying vec2 local_pos;

void vertex() {
	vec2 origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy;
	delay = (origin.x + origin.y * 0.5) * stagger;
	local_pos = VERTEX;
}

void fragment() {
	vec4 art = COLOR;
	// 0 to 1 while sweeping, then past 1 and off the image until the next one.
	float t = mod(TIME - delay, period) / sweep;
	vec2 at = local_space ? local_pos / max(box_size, vec2(1.0)) : UV;
	// A wide box leans the band by its height, not its width, so it does not
	// lie nearly flat across a long button.
	float lean = local_space ? slant * box_size.y / max(box_size.x, 1.0) : slant;
	float across = (at.x + (1.0 - at.y) * lean) / (1.0 + lean);
	float band_at = mix(-width, 1.0 + width, t);
	float band = 1.0 - smoothstep(0.0, width, abs(across - band_at));
	COLOR = vec4(mix(art.rgb, shine_color.rgb, band * strength), art.a);
}
