// A glint that sweeps across something earned every few seconds, so earned
// badges and stars look precious next to the matte locked ones.
//
// Only the band of light moves; the art underneath is untouched and keeps its
// own alpha, so the glint never spills outside the shape. Each copy starts its
// sweep a little later the further right and down it sits on screen, so a row
// of stars catches the light one after another rather than all at once.
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

varying float delay;

void vertex() {
	vec2 origin = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy;
	delay = (origin.x + origin.y * 0.5) * stagger;
}

void fragment() {
	vec4 art = COLOR;
	// 0 to 1 while sweeping, then past 1 and off the image until the next one.
	float t = mod(TIME - delay, period) / sweep;
	float across = (UV.x + (1.0 - UV.y) * slant) / (1.0 + slant);
	float band_at = mix(-width, 1.0 + width, t);
	float band = 1.0 - smoothstep(0.0, width, abs(across - band_at));
	COLOR = vec4(mix(art.rgb, shine_color.rgb, band * strength), art.a);
}
