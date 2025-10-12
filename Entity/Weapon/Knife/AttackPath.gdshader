shader_type canvas_item;
uniform sampler2D noise: filter_nearest, repeat_enable;
uniform sampler2D clip_curve;


void fragment() {
	float n = texture(noise, vec2(TIME/5., UV.y)).r;
	float pos = 1.-(abs(UV.x-0.5)*2.);
	pos = texture(clip_curve, vec2(UV.x, 0.0)).r;
	n = smoothstep(n, n+0.5, pos);
	
	
	
	const float EDGE_BLUR_DIST = 0.05;
	
	float edge1 = smoothstep(0.0, 0.0+EDGE_BLUR_DIST, UV.y);
	float edge2 = smoothstep(1.0, 1.0-EDGE_BLUR_DIST, UV.y);
	float edge_blur = min(edge1, edge2);
	
	
	COLOR = vec4(min(edge_blur, n) * 1.3);
}