shader_type spatial;

uniform float speed : hint_range(0.1, 5.0) = 1.0;
uniform float linger : hint_range(1.0, 5.0) = 2.0; // Controls how long each color lingers

void fragment() {
    float t = TIME * speed;

    // Adjust the sine curve to linger longer near peaks
    float r = pow(0.5 + 0.5 * sin(t), linger);
    float g = pow(0.5 + 0.5 * sin(t + 2.0944), linger);
    float b = pow(0.5 + 0.5 * sin(t + 4.1888), linger);

    vec3 color = vec3(r, g, b);

    // Preserve shading from lights
    ALBEDO = color;
}
