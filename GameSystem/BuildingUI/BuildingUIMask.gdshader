shader_type canvas_item;

void vertex() {
	// Called for every vertex the material is visible on.
}
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec4 s = texture(SCREEN_TEXTURE, SCREEN_UV);
	COLOR = s*c;
	//COLOR.a = 1.0;
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
