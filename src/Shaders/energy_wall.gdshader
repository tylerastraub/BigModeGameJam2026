shader_type spatial;
render_mode unshaded, blend_add;

uniform sampler2D albedo_texture;
uniform float scroll_speed = 0.04;
uniform float scale = 75.0;
uniform float gap_factor = 1.2;
uniform float opacity = 0.5;

void fragment() {
    vec2 offset_uv = UV - (TIME * vec2(0.0, scroll_speed));
    vec2 period = vec2(1.0, 1.0 / scale * gap_factor * 2.0);
	vec2 cell_idx = floor(offset_uv / period);
	vec2 pos = offset_uv - cell_idx * period;
    ALPHA = step(pos.y, 1.0 / scale) * opacity;
    ALBEDO = texture(albedo_texture, offset_uv * scale).rgb;
}
