// Indexed player sheets (board "v2.1: indexed pages + palettes"): the page is an 8-bit grayscale image whose value
// is a palette index (0 = transparent); `palette` is the sheet's 256 x 1 RGBA palette. One material per palette
// (scripts/sheets.gd material()), shared by every player wearing it. Works with the Sprite2D's region, flip_h and
// modulate (the vertex color), in GL Compatibility (Godot 4.3+).
shader_type canvas_item;

uniform sampler2D palette : filter_nearest, repeat_disable;

varying vec4 v_modulate;

void vertex() {
	v_modulate = COLOR;   // the sprite's modulate x self_modulate
}

void fragment() {
	float idx = texture(TEXTURE, UV).r;
	vec4 c = texture(palette, vec2((idx * 255.0 + 0.5) / 256.0, 0.5));
	if (idx < 0.5 / 255.0) {
		c.a = 0.0;
	}
	COLOR = c * v_modulate;
}
