// The sea of the chart: the engraved wave strokes of the old charts (two small
// arcs, rows offset by half a step), computed on the GPU from the position in
// the world, so that the sea costs nothing on the CPU however far one zooms.

shader_type canvas_item;

uniform vec4 lines_color : source_color = vec4(0.24, 0.4, 0.55, 0.55);
uniform vec2 spacing = vec2(120.0, 70.0);

varying vec2 world;

void vertex() {
    world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float arc(vec2 p, vec2 center) {
    vec2 d = p - center;
    float ring = abs(length(d) - 14.0);
    float width = fwidth(ring) + 1.0;
    float upper = smoothstep(-2.0, -6.0, d.y);
    return (1.0 - smoothstep(width - 1.0, width, ring)) * upper;
}

void fragment() {
    float row = floor(world.y / spacing.y);
    float shift = mod(row, 2.0) == 0.0 ? spacing.x * 0.5 : 0.0;
    vec2 p = vec2(mod(world.x - shift, spacing.x), mod(world.y, spacing.y));
    float stroke = max(arc(p, vec2(46.0, 35.0)), arc(p, vec2(74.0, 35.0)));
    COLOR = mix(COLOR, vec4(lines_color.rgb, 1.0), stroke * lines_color.a);
}
