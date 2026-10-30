shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform float fill_ratio : hint_range(0.0, 1.0) = 1.0;
uniform vec4 fill_color : source_color = vec4(0.2, 0.5, 1.0, 1.0);
uniform vec4 bg_color : source_color = vec4(0.1, 0.1, 0.1, 0.8);

void vertex() {
	// Spherical billboard: make the quad always face the camera
	mat4 n_out2p0 = MODELVIEW_MATRIX;
	n_out2p0[0] = vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0);
	n_out2p0[1] = vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0);
	n_out2p0[2] = vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0);
	// Keep the translation from the original modelview matrix
	MODELVIEW_MATRIX = n_out2p0;
}

void fragment() {
	if (UV.x < fill_ratio) {
		ALBEDO = fill_color.rgb;
		ALPHA = fill_color.a;
	} else {
		ALBEDO = bg_color.rgb;
		ALPHA = bg_color.a;
	}
}

