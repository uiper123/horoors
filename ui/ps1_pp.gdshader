shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform int color_depth : hint_range(1, 64) = 15;
uniform bool dithering = true;
uniform int resolution_scale : hint_range(1, 4) = 2;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Downscaling effect (pixelation) - naive approach
	// Better to use Viewport with SubViewportContainer, but this is shader-based
	// vec2 size = 1.0 / SCREEN_PIXEL_SIZE;
	// vec2 pixel_size = vec2(float(resolution_scale));
	// uv = floor(uv * size / pixel_size) * pixel_size / size;
	
	vec4 color = texture(SCREEN_TEXTURE, uv);
	
	if (dithering) {
		// Simple dithering pattern
		float dither_size = 4.0;
		vec2 dither_coord = mod(FRAGCOORD.xy / float(resolution_scale), dither_size);
		float dither_val = 0.0;
		
		int x = int(dither_coord.x);
		int y = int(dither_coord.y);
		
		// 4x4 Bayer Matrix
		if (x == 0) {
			if (y == 0) dither_val = 0.0/16.0; else if (y == 1) dither_val = 8.0/16.0; else if (y == 2) dither_val = 2.0/16.0; else if (y == 3) dither_val = 10.0/16.0;
		} else if (x == 1) {
			if (y == 0) dither_val = 12.0/16.0; else if (y == 1) dither_val = 4.0/16.0; else if (y == 2) dither_val = 14.0/16.0; else if (y == 3) dither_val = 6.0/16.0;
		} else if (x == 2) {
			if (y == 0) dither_val = 3.0/16.0; else if (y == 1) dither_val = 11.0/16.0; else if (y == 2) dither_val = 1.0/16.0; else if (y == 3) dither_val = 9.0/16.0;
		} else if (x == 3) {
			if (y == 0) dither_val = 15.0/16.0; else if (y == 1) dither_val = 7.0/16.0; else if (y == 2) dither_val = 13.0/16.0; else if (y == 3) dither_val = 5.0/16.0;
		}
		
		color.rgb += (dither_val - 0.5) / float(color_depth);
	}
	
	// Color depth reduction
	color.rgb = floor(color.rgb * float(color_depth)) / float(color_depth);
	
	COLOR = color;
}
