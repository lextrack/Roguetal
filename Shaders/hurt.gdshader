shader_type canvas_item;


uniform float flash_modifier : hint_range(0, 1) = 0.0;

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    vec3 flash_color = vec3(1.0, 0.0, 0.0); // Red flash color
    vec3 final_color = mix(texture_color.rgb, flash_color, flash_modifier);
    COLOR = vec4(final_color, texture_color.a);
}
