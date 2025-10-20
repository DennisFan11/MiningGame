shader_type canvas_item;

float sdBox(vec2 p, vec2 b) {
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

void fragment() {
	vec2 uv = UV; 
	//uv = (uv - 0.5) * 0.5 + 0.5; // 0.2 => 放大 5 倍
	uv +=  + vec2(TIME, 0.);
    vec2 p = fract(uv) - 0.5;

    // 方形半邊長（邊長 = 0.6）
    float dist = sdBox(p, vec2(0.3, 0.15)*0.7) - 0.1;

    // 填滿方形（邊界 dist=0，內部 dist<0）
    float fill = smoothstep(0.01, 0.0, dist);

    COLOR = vec4((fill));
}
