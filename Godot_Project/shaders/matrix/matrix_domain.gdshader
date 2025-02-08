// Source: Copyright (c) 2025 Steve Castellotti
// License: MIT License

shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_opaque;

uniform vec2 resolution = vec2(1024.0, 1024.0);
uniform float render_speed : hint_range(0.1, 2.0) = 0.36;
uniform float rain_speed   : hint_range(0.1, 10.0) = 1.0;
uniform bool domain_background_transparent = true;

// Domain text parameters:
//  - domain is an array (max length 256) of letter “codes” (see below)
//  - domain_length is the number of characters in the domain
//  - domain_column specifies in which text‐column the domain text will scroll
uniform float domain[256];
uniform int domain_length = 0;
uniform int domain_column = 0;

// Constants should match values from digital_matrix_rain.gdshader
// (same 6×7 sprite font and 8×10 letter grid)
const vec2 DS = vec2(6.0, 7.0);
const float LX = 8.0; // letter space x
const float LY = 10.0; // letter space y

float extract_bit(float n, float b) {
    b = clamp(b, -1.0, 22.0);
    return floor(mod(floor(n / pow(2.0, floor(b))), 2.0));
}

float sprite(vec2 spr, vec2 p) {
    // p is in pixel space (within one letter cell)
    vec2 uv = vec2(mod(floor(p.x), LX),
                   mod(floor(p.y), LY));
    uv = vec2(uv.x, DS.y - uv.y - 1.0);
    if (uv.x >= 0.0 && uv.y >= 0.0 && uv.x < DS.x && uv.y < DS.y) {
        float bit = (DS.x - uv.x) + uv.y * DS.x;
        float result = extract_bit(spr.x, bit - 21.0) + extract_bit(spr.y, bit);
        return result;
    }
    return 0.0;
}

vec2 getD(float d) {
    float index = floor(clamp(d, 0.0, 39.0));
    if (index == 0.0)  return vec2(935221.0,731292.0);   // 0
    if (index == 1.0)  return vec2(274497.0,33308.0);    // 1
    if (index == 2.0)  return vec2(934929.0,1116222.0);  // 2
    if (index == 3.0)  return vec2(934931.0,1058972.0);  // 3
    if (index == 4.0)  return vec2(137380.0,1302788.0);  // 4
    if (index == 5.0)  return vec2(2048263.0,1058972.0); // 5
    if (index == 6.0)  return vec2(401671.0,1190044.0);  // 6
    if (index == 7.0)  return vec2(2032673.0,66576.0);   // 7
    if (index == 8.0)  return vec2(935187.0,1190044.0);  // 8
    if (index == 9.0)  return vec2(935187.0,1581336.0);  // 9
    if (index == 10.0) return vec2(935188.0,780450.0);   // A
    if (index == 11.0) return vec2(1983767.0,1190076.0); // B
    if (index == 12.0) return vec2(935172.0,133276.0);   // C
    if (index == 13.0) return vec2(1983764.0,665788.0);  // D
    if (index == 14.0) return vec2(2048263.0,1181758.0); // E
    if (index == 15.0) return vec2(2048263.0,1181728.0); // F
    if (index == 16.0) return vec2(935173.0,1714334.0);  // G
    if (index == 17.0) return vec2(1131799.0,1714338.0); // H
    if (index == 18.0) return vec2(921665.0,33308.0);    // I
    if (index == 19.0) return vec2(66576.0,665756.0);    // J
    if (index == 20.0) return vec2(1132870.0,166178.0);  // K
    if (index == 21.0) return vec2(1065220.0,133182.0);  // L
    if (index == 22.0) return vec2(1142100.0,665762.0);  // M
    if (index == 23.0) return vec2(1140052.0,1714338.0); // N
    if (index == 24.0) return vec2(935188.0,665756.0);   // O
    if (index == 25.0) return vec2(1983767.0,1181728.0); // P
    if (index == 26.0) return vec2(935188.0,698650.0);   // Q
    if (index == 27.0) return vec2(1983767.0,1198242.0); // R
    if (index == 28.0) return vec2(935171.0,1058972.0);  // S
    if (index == 29.0) return vec2(2035777.0,33288.0);  // T
    if (index == 30.0) return vec2(1131796.0,665756.0);  // U
    if (index == 31.0) return vec2(1131796.0,664840.0);  // V
    if (index == 32.0) return vec2(1131861.0,699028.0);  // W
    if (index == 33.0) return vec2(1131681.0,84130.0);   // X
    if (index == 34.0) return vec2(1131794.0,1081864.0); // Y
    if (index == 35.0) return vec2(1968194.0,133180.0);  // Z
    if (index == 36.0) return vec2(0.0,1560.0);          // .
    if (index == 37.0) return vec2(7.0,1572864.0);       // -
    if (index == 38.0) return vec2(195.0,1560.0);        // :
    return vec2(0.0,0.0); // by default return empty space (" ")
}

// We use the same 8×10 grid as digital_matrix_rain shader. Only the fragments
// in the designated column (i.e. where floor(uv.x/LX)==domain_column) are affected.
// We “scroll” the text downward by computing a cell–coordinate scroll offset.
// In each valid cell (i.e. one that corresponds to a character in the domain),
// we compute the letter to show so that the last letter in the domain appears in the top cell.
// (That is, if domain_length is N, then in cell 0 we draw domain[N-1], in cell 1 we draw domain[N-2], etc.)
//
void fragment() {
    vec2 uv = UV * resolution;

    // Only operate on the chosen column
    if (floor(uv.x / LX) != float(domain_column)) {
        ALPHA = 0.0;
    } else {
        // Compute vertical scroll (in “cell” units)
        float scroll = TIME * rain_speed;
        // Compute the “text coordinate” (in cells); note that at TIME==0,
        // the top cell (n==0) will show the last letter of the domain.
        float t = (uv.y / LY) - scroll;
        float n = floor(t);
        if (n < 0.0 || n >= float(domain_length)) {
            ALPHA = 0.0;
        } else {

            // In order to show the text vertically with the last letter at the top,
            // we use the letter from our domain array at position: (domain_length - 1 - n)
            int idx = int(domain_length) - 1 - int(n);
            float letter = domain[idx];

            // Look up the sprite data for this letter.
            vec2 cd = getD(letter);

            // Determine the top–left corner of this letter’s cell.
            float cellY = (n + scroll) * LY;
            float cellX = float(domain_column) * LX;
            vec2 lp = vec2(uv.x - cellX, uv.y - cellY);

            // Call our sprite() function (which uses the same 6×7 font as before).
            float s = sprite(cd, lp);

            // In each cell we want to “mask out” the digital rain behind the domain text.
            // We do this by drawing a black background in the cell, then “painting” the letter (here in white)
            // where sprite() returns a value.
            vec3 col = mix(vec3(0.0), vec3(1.0), step(0.5, s));
            ALBEDO = col;
            // 99.95% black background, 0.05% transparency or solid black
            ALPHA = domain_background_transparent ? mix(0.0005, 1.0, step(0.5, s)) : 1.0;
        }
    }
}
