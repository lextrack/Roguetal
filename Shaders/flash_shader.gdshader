shader_type canvas_item;

uniform float flash_modifier : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    vec4 flash_color = vec4(1.0, 1.0, 1.0, color.a);
    COLOR = mix(color, flash_color, flash_modifier);
}