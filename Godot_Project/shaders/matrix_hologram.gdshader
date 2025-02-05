// Source: https://godotshaders.com/shader/matrix-style-3d-hologram/
// Credit: Matthias: https://godotshaders.com/author/matthias/
// License: MIT

shader_type spatial;

uniform sampler2D img;
uniform float x_scale = 10.0;
uniform float y_scale = 10.0;
uniform float time = 0.5;

void fragment(){
	float x = mod(UV.x, 1.0/x_scale);
	float y = mod(UV.y, 1.0/y_scale);
	EMISSION = vec3(0.0, 1.0, 0.0);

	float direction;
	if(mod(UV.x, 2.0/x_scale)-mod(x, 1.0/x_scale) == 0.0){
		direction = -TIME/3.0;
	}else{
		direction = TIME/3.0;
	}

	vec3 tex = texture(img, vec2(x*x_scale, direction+TIME+y*y_scale)).rgb;
	float brightness = mod(UV.y - (TIME*time) + y + UV.x-x, 0.5);
	ALPHA = 0.1+pow(tex.x * brightness, 0.75);
	if(ALPHA > 0.5){EMISSION = vec3(0.5, 1.0, 0.5);}
}
