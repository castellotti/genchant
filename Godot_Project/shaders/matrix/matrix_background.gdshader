// Source: https://www.shadertoy.com/view/XfGSzy
// Credit: https://www.shadertoy.com/user/rockhard
// License: Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License:
//          http://creativecommons.org/licenses/by-nc-sa/3.0/deed.en_US
// Sprite Source: https://www.shadertoy.com/view/llSGRm
// Sprite Sheet Source: http://uzebox.org/wiki/index.php?title=File:Font6x8.png

shader_type spatial;
render_mode unshaded;

uniform vec2 resolution = vec2(1024.0, 1024.0);
uniform float render_speed : hint_range(0.1, 2.0) = 0.36;
uniform float rain_speed : hint_range(0.1, 10.0) = 1.0;

// Character definitions
const vec2 ch0 = vec2(935221.0,731292.0);
const vec2 ch1 = vec2(274497.0,33308.0);
const vec2 ch2 = vec2(934929.0,1116222.0);
const vec2 ch3 = vec2(934931.0,1058972.0);
const vec2 ch4 = vec2(137380.0,1302788.0);
const vec2 ch5 = vec2(2048263.0,1058972.0);
const vec2 ch6 = vec2(401671.0,1190044.0);
const vec2 ch7 = vec2(2032673.0,66576.0);
const vec2 ch8 = vec2(935187.0,1190044.0);
const vec2 ch9 = vec2(935187.0,1581336.0);

const vec2 ch_A = vec2(935188.0,780450.0);   //const vec2 ch_a = vec2(224.0,649374.0);
const vec2 ch_B = vec2(1983767.0,1190076.0); //const vec2 ch_b = vec2(1065444.0,665788.0);
const vec2 ch_C = vec2(935172.0,133276.0);   //const vec2 ch_c = vec2(228.0,657564.0);
const vec2 ch_D = vec2(1983764.0,665788.0);  //const vec2 ch_d = vec2(66804.0,665758.0);
const vec2 ch_E = vec2(2048263.0,1181758.0); //const vec2 ch_e = vec2(228.0,772124.0);
const vec2 ch_F = vec2(2048263.0,1181728.0); //const vec2 ch_f = vec2(401543.0,1115152.0);
const vec2 ch_G = vec2(935173.0,1714334.0);  //const vec2 ch_g = vec2(244.0,665474.0);
const vec2 ch_H = vec2(1131799.0,1714338.0); //const vec2 ch_h = vec2(1065444.0,665762.0);
const vec2 ch_I = vec2(921665.0,33308.0);    //const vec2 ch_i = vec2(262209.0,33292.0);
const vec2 ch_J = vec2(66576.0,665756.0);    //const vec2 ch_j = vec2(131168.0,1066252.0);
const vec2 ch_K = vec2(1132870.0,166178.0);  //const vec2 ch_k = vec2(1065253.0,199204.0);
const vec2 ch_L = vec2(1065220.0,133182.0);  //const vec2 ch_l = vec2(266305.0,33292.0);
const vec2 ch_M = vec2(1142100.0,665762.0);  //const vec2 ch_m = vec2(421.0,698530.0);
const vec2 ch_N = vec2(1140052.0,1714338.0); //const vec2 ch_n = vec2(452.0,1198372.0);
const vec2 ch_O = vec2(935188.0,665756.0);   //const vec2 ch_o = vec2(228.0,665756.0);
const vec2 ch_P = vec2(1983767.0,1181728.0); //const vec2 ch_p = vec2(484.0,667424.0);
const vec2 ch_Q = vec2(935188.0,698650.0);   //const vec2 ch_q = vec2(244.0,665474.0);
const vec2 ch_R = vec2(1983767.0,1198242.0); //const vec2 ch_r = vec2(354.0,590904.0);
const vec2 ch_S = vec2(935171.0,1058972.0);  //const vec2 ch_s = vec2(228.0,114844.0);
const vec2 ch_T = vec2(935171.0,1058972.0);  //const vec2 ch_t = vec2(8674.0,66824.0);
const vec2 ch_U = vec2(1131796.0,665756.0);  //const vec2 ch_u = vec2(292.0,1198868.0);
const vec2 ch_V = vec2(1131796.0,664840.0);  //const vec2 ch_v = vec2(276.0,664840.0);
const vec2 ch_W = vec2(1131861.0,699028.0);  //const vec2 ch_w = vec2(276.0,700308.0);
const vec2 ch_X = vec2(1131681.0,84130.0);   //const vec2 ch_x = vec2(292.0,1149220.0);
const vec2 ch_Y = vec2(1131794.0,1081864.0); //const vec2 ch_y = vec2(292.0,1163824.0);
const vec2 ch_Z = vec2(1968194.0,133180.0);  //const vec2 ch_z = vec2(480.0,1148988.0);

const vec2 ch_dot  = vec2(0.0,1560.0);
const vec2 ch_dash = vec2(7.0,1572864.0);
const vec2 ch_colon = vec2(195.0,1560.0);
const vec2 ch_space = vec2(0.0,0.0); // defined but not displayed

const vec2 DS = vec2(6.0,7.0); // digital size
const float LX = 8.0; // letter space x
const float LY = 10.0; // letter space y

float rand(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43.5453123);
}

float extract_bit(float n, float b) {
    b = clamp(b, -1.0, 22.0);
    return floor(mod(floor(n / pow(2.0, floor(b))), 2.0));
}

float sprite(vec2 spr, vec2 p) {
    vec2 uv = vec2(
        mod(floor(p.x), LX),
        mod(floor(p.y), LY)
    );
    uv = vec2(uv.x, DS.y - uv.y - 1.0);

    if(uv.x >= 0.0 && uv.y >= 0.0 && uv.x < DS.x && uv.y < DS.y) {
        float bit = (DS.x-uv.x) + uv.y * DS.x;
        float result = extract_bit(spr.x, bit - 21.0) + extract_bit(spr.y, bit);
        return result;
    }
    return 0.0;
}

vec2 getD(float d) {
    float index = floor(clamp(d, 0.0, 39.0));

    if(index == 0.0) return ch0;
    if(index == 1.0) return ch1;
    if(index == 2.0) return ch2;
    if(index == 3.0) return ch3;
    if(index == 4.0) return ch4;
    if(index == 5.0) return ch5;
    if(index == 6.0) return ch6;
    if(index == 7.0) return ch7;
    if(index == 8.0) return ch8;
    if(index == 9.0) return ch9;
    if(index == 10.0) return ch_A;
    if(index == 11.0) return ch_B;
    if(index == 12.0) return ch_C;
    if(index == 13.0) return ch_D;
    if(index == 14.0) return ch_E;
    if(index == 15.0) return ch_F;
    if(index == 16.0) return ch_G;
    if(index == 17.0) return ch_H;
    if(index == 18.0) return ch_I;
    if(index == 19.0) return ch_J;
    if(index == 20.0) return ch_K;
    if(index == 21.0) return ch_L;
    if(index == 22.0) return ch_M;
    if(index == 23.0) return ch_N;
    if(index == 24.0) return ch_O;
    if(index == 25.0) return ch_P;
    if(index == 26.0) return ch_Q;
    if(index == 27.0) return ch_R;
    if(index == 28.0) return ch_S;
    if(index == 29.0) return ch_T;
    if(index == 30.0) return ch_U;
    if(index == 31.0) return ch_V;
    if(index == 32.0) return ch_W;
    if(index == 33.0) return ch_X;
    if(index == 34.0) return ch_Y;
    if(index == 35.0) return ch_Z;
    if(index == 36.0) return ch_dot;
    if(index == 37.0) return ch_dash;
    if(index == 38.0) return ch_colon;
    if(index == 39.0) return ch_space; // not displayed due to floor clamped at 39.0
    return vec2(0.0, 0.0);
}

float rain(vec2 p) {
    // p is now in screen space (unflipped)
    vec2 pos = floor(p);
    pos.x -= mod(pos.x, LX);

    float offset = sin(pos.x * LX);
    float column_speed = abs(cos(pos.x * 2.0)) * 0.12 + 0.08;

    // Here we use the Y coordinate from the top.
    float normalizedY = (resolution.y - p.y) / resolution.y;
    float timeOffset = TIME * column_speed * rain_speed;

    // When TIME increases, the fract value cycles so that rain appears to fall downward.
    float yPos = fract(normalizedY + timeOffset + offset);

    return 0.08 / max(yPos, 0.001);
}

void fragment() {
    // Calculate base UV coordinates
    vec2 uv = UV * resolution;

    // Calculate rain effect
    float rain_value = rain(uv);

    // Calculate character
    vec2 grid = vec2(LX, LY);
    vec2 suv = mod(uv, grid) / grid;
    vec2 block = floor(uv / grid);

    float time_offset = rand(block) + TIME * render_speed;
    float char_index = mod(time_offset * 10.0, 39.0);

    vec2 char_data = getD(char_index);
    float sprite_value = sprite(char_data, uv);

    // Combine effects
    float final_value = sprite_value * rain_value;

    // Output color
    ALBEDO = vec3(0.15 * final_value, 0.9 * final_value, 0.1 * final_value);
    ALPHA = 1.0;
}
