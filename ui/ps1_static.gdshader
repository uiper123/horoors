shader_type spatial;
render_mode skip_vertex_transform, diffuse_lambert, specular_disabled;

uniform float jitter: hint_range(0.0, 1.0) = 0.5;
uniform bool affine_texture_mapping = true;
uniform vec2 resolution = vec2(320, 240);
uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float fog_start : hint_range(0.0, 50.0) = 5.0;
uniform float fog_end : hint_range(0.0, 100.0) = 25.0;
uniform vec3 fog_color : source_color = vec3(0.02, 0.03, 0.04);
uniform float alpha_scissor : hint_range(0.0, 1.0) = 0.5;

varying float z_dist;
varying vec2 uv_affine;
varying float fog_factor;

void vertex() {
	// Transform to View Space (NO WIND HERE)
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	NORMAL = (MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	
	// Jitter (Snap to grid)
	float z = -VERTEX.z;
	vec4 pos = PROJECTION_MATRIX * vec4(VERTEX, 1.0);
	
	if (z > 0.0) {
		vec2 snap_res = resolution;
		vec4 pos_snapped = pos;
		pos_snapped.xy = floor(pos.xy / pos.w * snap_res) / snap_res * pos.w;
		POSITION = mix(pos, pos_snapped, jitter);
	} else {
		POSITION = pos;
	}
	
	// Affine Texture Mapping
	uv_affine = UV;
	if (affine_texture_mapping) {
		uv_affine *= z;
		z_dist = z;
	}
	
	// Vertex Fog
	fog_factor = clamp((fog_end - z) / (fog_end - fog_start), 0.0, 1.0);
}

void fragment() {
	vec2 uv = uv_affine;
	
	if (affine_texture_mapping && z_dist > 0.0) {
		uv /= z_dist;
	}
	
	vec4 tex = texture(albedo_texture, uv);
	if (tex.a < alpha_scissor) {
		discard;
	}
	
	vec3 tex_color = tex.rgb * albedo_color.rgb;
	ALBEDO = mix(fog_color, tex_color, fog_factor);
}