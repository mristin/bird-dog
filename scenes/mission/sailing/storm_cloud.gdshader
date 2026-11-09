// A storm cloud seen from above (see storm_cloud.gd), in three layers:
//
// * the cloud (layer 0): billowing fractal noise, warped so that it churns
//   slowly, lit from the top left, darker and denser in the middle, with soft
//   ragged edges, and a flash of lightning now and then;
// * its shadow on the sea (layer 1), offset by the sun;
// * the rain under the cloud (layer 2): a grey veil which drifts in sheets
//   with the wind, streaks of falling rain in three depths (the near ones
//   longer, brighter and faster, all slanted by the wind and blurred by their
//   motion), and the rings of the drops which hit the sea.

shader_type canvas_item;

uniform float seed = 0.0;
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
// 0: the cloud, 1: its shadow, 2: the rain.
uniform int layer = 0;
// A storm is darker, with more and heavier rain.
uniform bool storm = false;
// How opaque the cloud is at most: the sea and the boats show through it.
uniform float opacity : hint_range(0.0, 1.0) = 0.5;
// Where the wind blows to, on the screen (y points south).
uniform vec2 wind = vec2(0.0, 1.0);
// The size of the layer in pixels, so that the drops keep their size
// whatever the size of the cloud.
uniform vec2 size_px = vec2(600.0, 600.0);

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

// Five octaves for the cloud, fewer for its shadow and the rain (which are
// blurry anyway).
float fbm(vec2 p, int octaves) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < octaves; i++) {
        value += amplitude * noise(p);
        p = p * 2.03 + vec2(1.7, 9.2);
        amplitude *= 0.5;
    }
    return value;
}

// How dense the cloud is at the point (uv from -1 to 1).
float density(vec2 uv, int octaves) {
    float r = length(uv);
    float t = TIME * 0.025;
    vec2 q = uv * 2.4 + vec2(seed * 13.1, seed * 7.7);
    vec2 warp = vec2(fbm(q + vec2(t, 0.0), octaves), fbm(q + vec2(5.2, 1.3) - vec2(0.0, t), octaves));
    float falloff = smoothstep(1.0, 0.3, r);
    float n = fbm(q + 1.6 * warp, octaves);
    return clamp((n - 0.38) * 2.4 + falloff * 1.1 - 0.3, 0.0, 1.0) * falloff;
}

// One depth of falling rain: streaks in tall cells which run along the way the
// rain falls; [scale] is the width of a cell in pixels, [speed] in cells per
// second. Returns the brightness of the streaks at the pixel.
float streaks(vec2 px, vec2 fall, float scale, float speed, float chance, float salt) {
    // NOTE (mristin):
    // The frame of the rain: y along the fall, x across it.
    vec2 across = vec2(fall.y, -fall.x);
    vec2 q = vec2(dot(px, across), dot(px, fall)) / scale;
    float tall = 7.0;
    q.y = q.y / tall - TIME * speed / tall;
    vec2 cell = floor(q);
    vec2 f = fract(q);
    float h = hash(cell + salt);
    if (h > chance) {
        return 0.0;
    }
    float x = (f.x - (0.15 + 0.7 * hash(cell + salt + 3.1))) * scale;
    float length_share = 0.35 + 0.45 * hash(cell + salt + 1.3);
    float top = hash(cell + salt + 7.7) * (1.0 - length_share);
    float along = (f.y - top) / length_share;
    if (along < 0.0 || along > 1.0) {
        return 0.0;
    }
    // A drop smeared by its motion: bright at its head, fading to its tail,
    // a pixel or two wide with a soft edge.
    float width = 0.6 + 0.5 * hash(cell + salt + 5.3);
    float line = exp(-x * x / (width * width));
    float smear = smoothstep(0.0, 0.25, along) * (0.35 + 0.65 * along) * smoothstep(1.0, 0.92, along);
    return line * smear * (0.6 + 0.4 * h / chance);
}

// The rings of the drops which hit the sea: every cell of [scale] pixels gets
// a drop now and then at a random spot; its ring widens and fades.
float ripples(vec2 px, float scale, float chance, float salt) {
    vec2 q = px / scale;
    vec2 cell = floor(q);
    float h = hash(cell + salt);
    if (h > chance) {
        return 0.0;
    }
    float period = 0.7 + 0.6 * hash(cell + salt + 2.7);
    float phase = fract(TIME / period + hash(cell + salt + 4.1));
    vec2 center = (cell + vec2(0.2, 0.2) + 0.6 * vec2(hash(cell + salt + 6.6), hash(cell + salt + 8.8))) * scale;
    float radius = 1.0 + phase * scale * 0.42;
    float d = abs(length(px - center) - radius);
    return smoothstep(1.3, 0.0, d) * (1.0 - phase) * (1.0 - phase);
}

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    float r = length(uv);
    if (r > 1.0) {
        discard;
    }

    if (layer == 1) {
        float d = density(uv, 3);
        COLOR = vec4(0.04, 0.07, 0.12, d * 0.4 * strength * opacity);
    } else if (layer == 2) {
        float d = density(uv, 3);
        vec2 px = UV * size_px;
        vec2 drift = wind * 0.55;
        vec2 fall = normalize(vec2(0.0, 1.0) + drift);

        // NOTE (mristin):
        // The rain falls in sheets: a slow noise, drifting with the wind,
        // makes it heavier and lighter, so that the veil moves.
        float sheets = fbm(px / 140.0 - wind * TIME * 0.35 + seed, 3);
        float heavy = storm ? 1.0 : 0.65;
        float rain = smoothstep(0.12, 0.55, d) * (0.55 + 0.9 * sheets) * heavy;
        rain = clamp(rain, 0.0, 1.0);

        float near = streaks(px, fall, 9.0, 34.0, 0.32 * heavy + 0.1, 11.0);
        float middle = streaks(px + vec2(37.0, 11.0), fall, 6.0, 26.0, 0.4 * heavy + 0.1, 23.0) * 0.7;
        float far = streaks(px + vec2(5.0, 61.0), fall, 4.0, 19.0, 0.5 * heavy + 0.1, 37.0) * 0.45;
        float drops = clamp(near + middle + far, 0.0, 1.0);
        float rings = ripples(px, 16.0, 0.55 * heavy, 51.0) + ripples(px + vec2(8.0), 23.0, 0.45 * heavy, 67.0) * 0.8;

        // The veil: the grey of the rain, which hides the sea a little.
        vec3 veil = mix(vec3(0.36, 0.4, 0.46), vec3(0.22, 0.25, 0.3), storm ? 0.7 : 0.3);
        vec3 light = vec3(0.86, 0.9, 0.95);
        float veil_alpha = rain * 0.55;
        float bright = (drops * 0.85 + clamp(rings, 0.0, 1.0) * 0.45) * rain;
        vec3 color = mix(veil, light, clamp(bright / max(veil_alpha + bright, 0.001), 0.0, 1.0));
        color = mix(color, vec3(1.0, 0.98, 0.88), flash * rain * 0.5);
        COLOR = vec4(color, clamp(veil_alpha + bright, 0.0, 1.0) * strength * opacity * 1.3);
    } else {
        int octaves = 5;
        float t = TIME * 0.025;
        vec2 q = uv * 2.4 + vec2(seed * 13.1, seed * 7.7);

        // NOTE (mristin):
        // The warp is computed once, and the light reuses it: a cloud costs four
        // noises of five octaves per pixel.
        vec2 warp = vec2(fbm(q + vec2(t, 0.0), octaves), fbm(q + vec2(5.2, 1.3) - vec2(0.0, t), octaves));
        float falloff = smoothstep(1.0, 0.3, r);
        float n = fbm(q + 1.6 * warp, octaves);
        float d = clamp((n - 0.38) * 2.4 + falloff * 1.1 - 0.3, 0.0, 1.0) * falloff;
        float n_lit = fbm(q + vec2(-0.084, -0.108) + 1.6 * warp, octaves);
        float light = clamp(0.5 + (n_lit - n) * 4.0 * 2.4 * falloff, 0.0, 1.0);
        vec3 core = storm ? vec3(0.1, 0.11, 0.15) : vec3(0.2, 0.22, 0.27);
        vec3 edge = vec3(0.78, 0.8, 0.84);
        vec3 color = mix(core, edge, clamp((1.0 - d) * 0.7 + light * 0.5, 0.0, 1.0));
        color = mix(color, vec3(1.0, 0.97, 0.82), flash * smoothstep(0.1, 0.8, d) * 0.85);
        // The middle of the cloud thins a little, so that the rain below it
        // shows through.
        COLOR = vec4(color, smoothstep(0.02, 0.3, d) * opacity * strength * (1.0 - 0.25 * smoothstep(0.5, 0.9, d)));
    }
}
