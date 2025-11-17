shader_type canvas_item;

uniform float edge: hint_range(0.0, 0.7, 0.01) = 0.7;
uniform vec4 color : source_color; // 邊線顏色
uniform float line_thickness: hint_range(0.001, 0.1, 0.001) = 0.02;

float sdBox(vec2 p, vec2 b){
    vec2 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

void fragment() {
    vec2 uv = UV - vec2(0.5);

    float angle = PI / 4.0;
    float c = cos(angle);
    float s = sin(angle);
    mat2 rot = mat2(vec2(c, -s), vec2(s, c));
    uv = rot * uv;

    float dist = sdBox(uv, vec2(edge, edge));

    // 邊線區域（非漸層）
    float border = step(abs(dist), line_thickness);

    // 方塊內部透明
    float inside = step(dist, 0.0);

    vec4 texColor = texture(TEXTURE, UV);

    // 邏輯：
    // 邊線 → color
    // 內部 → 透明
    // 外部 → 原貼圖
    COLOR = mix(texColor, color, border);
    COLOR.a = mix(texColor.a, 1.0, border * color.a);

    // 內部透明處理（可選：若要保留內部透明）
    if (inside > 0.0 && border == 0.0) {
        COLOR.a = 0.0;
    }
}
