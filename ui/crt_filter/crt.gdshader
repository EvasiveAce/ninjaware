shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Set this to the CRTPanel's actual Size (in game pixels).
uniform vec2 panel_size = vec2(256.0, 240.0);

uniform bool enable_grain = false;
uniform bool enable_curving = false;
uniform bool enable_scanlines = true;
uniform bool enable_chromatic_aberration = false;
uniform bool enable_rgb_grid = false;
uniform bool enable_vhs_wiggle = false;
uniform bool enable_vignette = true;
uniform float brightness_multiplier : hint_range(1.0, 10.0, 0.01) = 1.15;

group_uniforms grain_settings;
uniform float grain_strength : hint_range(0.0, 1.0, 0.01) = 0.02;

group_uniforms curving_settings;
uniform float curve_power : hint_range(1.0, 1.05, 0.005) = 1.02;

group_uniforms vignette_settings;
uniform float vignette_size : hint_range(0.1, 10.0, 0.05) = 0.4;
uniform float vignette_smoothness : hint_range(0.05, 5.0, 0.05) = 0.4;
uniform float vignette_strength : hint_range(0.0, 1.0, 0.01) = 0.6;

group_uniforms scanlines_settings;
uniform float scanlines_interval : hint_range(1.0, 20.0, 1.0) = 2.0;
uniform float scanline_opacity : hint_range(0.0, 1.0, 0.01) = 0.10;
uniform float scanline_thickness : hint_range(0.0, 10.0, 1.0) = 1.0;

group_uniforms chromatic_aberration_settings;
uniform float chromatic_aberration_strength : hint_range(0.0, 10.0, 0.1) = 1.0;

group_uniforms vhs_wiggle_settings;
uniform sampler2D noise_texture : filter_linear_mipmap, repeat_enable;
uniform float wiggle : hint_range(0.0, 0.05, 0.001) = 0.002;

vec2 distort(vec2 p)
{
	float theta = atan(p.y, p.x);
	float radius = pow(length(p), curve_power);

	p.x = radius * cos(theta);
	p.y = radius * sin(theta);

	return 0.5 * (p + vec2(1.0, 1.0));
}

float filmGrainNoise(in float time, in vec2 uv)
{
	return fract(sin(dot(uv, vec2(12.9898, 78.233) * time)) * 43758.5453);
}

float v2random(vec2 uv)
{
	return texture(noise_texture, mod(uv, vec2(1.0))).x;
}

void fragment()
{
	vec2 xy = SCREEN_UV;

	if (enable_vhs_wiggle)
	{
		xy.x += (v2random(vec2(xy.y / 10.0, TIME / 10.0)) - 0.5) * wiggle * 0.1;
		xy.x += (v2random(vec2(xy.y, TIME * 10.0)) - 0.5) * wiggle * 0.1;
	}

	if (enable_curving)
	{
		xy *= 2.0;
		xy -= vec2(1.0);
		xy = distort(xy);
	}

	vec4 color = texture(screen_texture, xy);

	if (enable_chromatic_aberration)
	{
		// Don't shift near the panel edges, so we never sample the cabinet frame.
		float x_px = UV.x * panel_size.x;
		float inside = step(chromatic_aberration_strength, x_px)
				* step(x_px, panel_size.x - chromatic_aberration_strength);
		vec2 off = SCREEN_PIXEL_SIZE * vec2(chromatic_aberration_strength, 0.0) * inside;

		float r = texture(screen_texture, xy + off).r;
		float g = texture(screen_texture, xy).g;
		float b = texture(screen_texture, xy - off).b;
		color.rgb = vec3(r, g, b);
	}

	if (enable_grain)
		color.rgb = mix(color.rgb, vec3(0.0), filmGrainNoise(TIME, SCREEN_UV) * grain_strength);

	if (enable_rgb_grid)
	{
		int rgbIndex = int(FRAGCOORD.x) % 3;
		vec3 mask = vec3(
			rgbIndex == 0 ? 1.0 : 0.0,
			rgbIndex == 1 ? 1.0 : 0.0,
			rgbIndex == 2 ? 1.0 : 0.0
		);
		color.rgb *= mask;
	}

	color.rgb *= brightness_multiplier;

	if (enable_scanlines)
	{
		float scanline = mod(floor(FRAGCOORD.y), scanlines_interval);
		scanline = 1.0 - step(scanline_thickness, scanline);
		scanline *= scanline_opacity;
		color.rgb *= 1.0 - scanline;
	}

	if (enable_vignette)
	{
		// Uses the panel's own UV, so the vignette fits the CRTPanel rather than the whole window.
		vec2 vuv = UV;
		vuv *= 1.0 - vuv.yx;
		float vig = vuv.x * vuv.y / vignette_size * 1000.0;
		vig = clamp(pow(vig, 1.0 / vignette_smoothness), 0.0, 1.0);
		color.rgb *= mix(1.0, vig, vignette_strength);
	}

	COLOR = color;
}