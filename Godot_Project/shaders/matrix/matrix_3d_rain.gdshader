// Source: https://www.shadertoy.com/view/MsVBDG
// Credit: https://www.shadertoy.com/user/laserdog
// Texture Credit: https://www.shadertoy.com/user/otaviogood
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License:
//          http://creativecommons.org/licenses/by-nc-sa/3.0/deed.en_US

shader_type canvas_item;

uniform float time;
uniform sampler2D matrix_texture : repeat_enable;

const float distance_falloff_modifier = 0.3; // default: 0.3
const float horizon_width = 0.024; // default: 0.05
const float horizon_position = 0.1; // default: 0.15
const float brightness = 15.0; // 1.5 to 35.0 is a good range

float random(float x) {
    return fract(sin(x) * 10000.0);
}

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    vec2 lookup = vec2(uv.x / uv.y, 0.5 / uv.y) * 0.55;
    float rand = random(floor(lookup.x * 16.0)) + 0.1;
    float ySign = sign(uv.y);

    vec2 tex_coords = lookup;
    tex_coords.y = fract(tex_coords.y + time * rand * ySign);

    float r = texture(matrix_texture, tex_coords).r;
    r *= step(0.1 / 16.0, abs(lookup.x - round(lookup.x * 16.0) / 16.0));

    // Create stronger distance falloff
    float distance_falloff = 1.0 - pow(abs(uv.y), distance_falloff_modifier);

    // Add horizon fade
    float horizon = 1.0 - smoothstep(horizon_width, horizon_position, abs(uv.y));

    // Combine the falloffs
    float final_falloff = distance_falloff * (1.0 - horizon);
    r *= final_falloff;

    // Adjust the final color intensity
    vec3 color = vec3(0.0, 1.0, 0.2) * r * brightness;
    COLOR = vec4(color, 0.5);
}
