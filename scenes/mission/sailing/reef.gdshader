// A field of reefs seen from above (see reef_patch.gd), in the manner of the
// reefs of Pirates! Gold: a patch of pale turquoise shallow water with the
// sunlight rippling on the bottom, dark rocks which break the surface, lit
// from the top left, and white foam which keeps breaking around them.
//
// The rocks come as positions in pixels relative to the middle of the quad,
// so that the picture matches the rocks which the boats hit.

shader_type canvas_item;

const int MAX_ROCKS = 12;

uniform vec2 rocks[MAX_ROCKS];
uniform int count = 0;
// The radius of a rock, in pixels.
uniform float radius = 28.0;
// Half the size of the quad, in pixels.
uniform float half_size = 200.0;
uniform float seed = 0.0;
uniform vec4 sea_color : source_color = vec4(0.33, 0.52, 0.66, 1.0);

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

// Four octaves are enough at the size of a reef, and keep it fast.
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p);
        p = p * 2.07 + vec2(3.1, 1.7);
        amplitude *= 0.5;
    }
    return value;
}

// The soft blobs around the rocks: a wide spread makes the shallows around
// them, a narrow one the rocks. Both are roughened by the same noise.
vec2 blobs(vec2 p) {
    vec2 sum = vec2(0.0);
    for (int i = 0; i < MAX_ROCKS; i++) {
        if (i >= count) {
            break;
        }
        vec2 d = (p - rocks[i]) / radius;
        float r2 = dot(d, d);
        sum += vec2(exp(-r2 * 0.9), exp(-r2 * 0.2));
    }
    return sum;
}

void fragment() {
    vec2 p = (UV * 2.0 - 1.0) * half_size;
    float t = TIME;

    // NOTE (mristin):
    // Every noise is computed once per pixel: the roughness of the rocks, the
    // waves of the foam and the ripples of the light.
    float rough = (fbm(p * 0.045 + seed) - 0.5) * 0.55;
    vec2 here = blobs(p) + rough;
    float f = here.x;
    float wide = here.y;

    // The shallow water reaches far around the rocks: a lagoon of turquoise
    // over pale sand, with a darker drop-off where it meets the deep sea.
    float shallow = smoothstep(0.35, 0.6, wide);
    float drop = smoothstep(0.2, 0.38, wide) * (1.0 - shallow);
    vec3 turquoise = vec3(0.36, 0.74, 0.78);
    vec3 color = mix(sea_color.rgb, sea_color.rgb * 0.72, drop);
    color = mix(color, turquoise, shallow);
    float sand = smoothstep(0.7, 1.3, wide);
    color = mix(color, vec3(0.68, 0.86, 0.8), sand * 0.55);

    // The sunlight rippling on the bottom (caustics).
    float ripple = fbm(p * 0.06 + vec2(t * 0.25, -t * 0.18) + seed);
    color += vec3(0.25, 0.3, 0.28) * smoothstep(0.55, 0.75, ripple) * shallow;

    // The foam breaking around the rocks, a band which moves with the waves.
    float wave = (ripple - 0.5) * 0.35;
    float foam = smoothstep(0.5, 0.58, f + wave) * (1.0 - smoothstep(0.66, 0.74, f + wave * 0.5));
    float pulse = 0.5 + 0.5 * sin(t * 2.2 - f * 9.0);
    color = mix(color, vec3(1.0), clamp(foam * (0.6 + 0.4 * pulse), 0.0, 1.0));

    // The rocks, lit from the top left, with a bright rim on the sunny side.
    float rock = smoothstep(0.7, 0.76, f);
    if (rock > 0.0) {
        float lit = blobs(p + vec2(-3.0, -3.0)).x + rough - f;
        vec3 stone = mix(vec3(0.24, 0.21, 0.19), vec3(0.62, 0.57, 0.5), clamp(0.45 + lit * 6.0, 0.0, 1.0));
        stone *= 0.85 + 0.3 * noise(p * 0.25 + seed);
        color = mix(color, stone, rock);
    }

    float edge = 1.0 - smoothstep(0.85, 1.0, length(UV * 2.0 - 1.0));
    COLOR = vec4(color, max(max(shallow, drop), rock) * edge);
}
