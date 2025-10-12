shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float circle_weight: hint_range(0.0, 1.0, 0.05) = 0.;

float circleSDF(vec2 p, vec2 center, float radius) {
    return length(p - center) - radius;
}
float sdBox( in vec2 p, in vec2 b ){
    vec2 d = abs(p)-b;
    return length(max(d,0.0)) + min(max(d.x,d.y),0.0);
}



const float BLOCK_SIZE = 16.0 * 5.;



varying mat4 world_to_screen;
varying mat4 screen_to_world;
void vertex(){
	world_to_screen = SCREEN_MATRIX * CANVAS_MATRIX;
	screen_to_world = inverse(world_to_screen);
}
// Puts SCREEN_UV in world space
vec2 SCREEN_UV_2_world(vec2 uv){
	uv = uv * 2.0 - 1.0;
	uv = (screen_to_world * vec4(uv,0,1)).xy;
	return uv;
}
// Puts SCREEN_UV back in screen space
vec2 world_to_SCREEN_UV(vec2 uv){
	uv = (world_to_screen * vec4(uv,0,1)).xy;
	uv = uv * 0.5 + 0.5;
	return uv;
}

uniform sampler2D curve;
void fragment() {

	float dist = texture_sdf(screen_uv_to_sdf(SCREEN_UV));
	float circle_dist = -circleSDF(SCREEN_UV_2_world(SCREEN_UV), vec2(0.), 10.);
	float box_dist = -sdBox(SCREEN_UV_2_world(SCREEN_UV), vec2(10.));
	circle_dist = mix(circle_dist, box_dist, 0.5);

	float _circle_weight = sin(TIME*1.5)/2.+.5;
	dist = mix(dist, circle_dist, circle_weight);

	dist += BLOCK_SIZE * 3.; // 內縮三格
	dist /= 240.;
	dist = clamp(dist, 0.0, 1.0);
	dist = texture(curve, vec2(dist, 0.0)).r;


	// CanvasGroup 預設
	vec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);
    //if (c.a > 0.0001) {
        //c.rgb /= c.a;
    //}
    COLOR *= c;


	COLOR.rgb *= dist;

}