shader_type canvas_item;

uniform float fill_amount : hint_range(0.0, 1.0) = 0.0;

uniform vec4 layer_color_0 : source_color = vec4(0.0);
uniform vec4 layer_color_1 : source_color = vec4(0.0);
uniform vec4 layer_color_2 : source_color = vec4(0.0);
uniform vec4 layer_color_3 : source_color = vec4(0.0);

uniform float wave_height : hint_range(0.0, 0.05) = 0.012;
uniform float wave_speed = 2.0;
uniform float wave_frequency = 14.0;

// These values match the vertical bounds of potion_bottle_fill_mask.svg.
const float CAVITY_TOP = 49.0 / 270.0;
const float CAVITY_BOTTOM = 244.0 / 270.0;
const float LAYER_COUNT = 4.0;


vec4 get_layer_color(float normalized_height) {
	int layer_index = int(floor(normalized_height * LAYER_COUNT));

	if (layer_index <= 0) {
		return layer_color_0;
	}
	if (layer_index == 1) {
		return layer_color_1;
	}
	if (layer_index == 2) {
		return layer_color_2;
	}

	return layer_color_3;
}


void fragment() {
	float mask_alpha = texture(TEXTURE, UV).a;
	float normalized_height = clamp(
		(CAVITY_BOTTOM - UV.y) / (CAVITY_BOTTOM - CAVITY_TOP),
		0.0,
		0.9999
	);

	vec4 liquid_color = get_layer_color(normalized_height);

	// Fade the wave away at the completely empty and full endpoints.
	float wave_weight = 4.0 * fill_amount * (1.0 - fill_amount);
	float wave = sin(
		UV.x * wave_frequency + TIME * wave_speed
	) * wave_height * wave_weight;

	float surface_y = mix(
		CAVITY_BOTTOM,
		CAVITY_TOP,
		fill_amount
	) + wave;
	float filled = smoothstep(
		surface_y - 0.006,
		surface_y + 0.006,
		UV.y
	);

	COLOR = vec4(
		liquid_color.rgb,
		liquid_color.a * mask_alpha * filled
	);
}
