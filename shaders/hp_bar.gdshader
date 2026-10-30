shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, skip_vertex_transform;

uniform float fill_ratio : hint_range(0.0, 1.0) = 1.0;
uniform vec4 fill_color : source_color = vec4(0.2, 0.5, 1.0, 1.0);
uniform vec4 bg_color : source_color = vec4(0.1, 0.1, 0.1, 0.8);

void vertex() {
	// Billboard: extract camera right and up from view matrix
	vec3 right = vec3(INV_VIEW_MATRIX[0][0], INV_VIEW_MATRIX[1][0], INV_VIEW_MATRIX[2][0]);
	vec3 up = vec3(INV_VIEW_MATRIX[0][1], INV_VIEW_MATRIX[1][1], INV_VIEW_MATRIX[2][1]);

	vec3 world_pos = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 offset = right * VERTEX.x + up * VERTEX.y;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(world_pos + offset, 1.0);
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
