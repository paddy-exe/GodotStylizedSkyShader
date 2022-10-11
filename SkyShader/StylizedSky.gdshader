// Shader Code origin from here: https://www.patreon.com/posts/making-stylized-27402644 by MinionsArt

shader_type sky;
render_mode use_half_res_pass;

// Horizon
uniform float offset_horizon : hint_range(-1.0, 1.0, 0.001) = 0.236;
uniform float horizon_intensity : hint_range(-10.0, 5.0, 0.001) = -0.443;
uniform vec4 sun_set : source_color = vec4(0.56, 0.24, 0.0, 1.0);
uniform vec4 horizon_color_day : source_color = vec4(0.57, 0.53, 0.26, 1.0);
uniform vec4 horizon_color_night : source_color = vec4(0.09, 0.16, 0.04, 1.0);

// Sun
uniform vec4 sun_color : source_color = vec4(1.0);
uniform float sun_radius : hint_range(0.0, 2.0, 0.001) = 0.2;
uniform bool flat_sun = true;

// Moon
uniform vec4 moon_color : source_color = vec4(1.0);
uniform float moon_radius : hint_range(0.0, 2.0, 0.01) = 0.05;
// negative: crescent on right side
// positive: crescent on left side 
uniform float moon_crescent : hint_range(-0.3, 0.3, 0.001) = -0.024;
uniform float dark_falloff : hint_range(1.0, 6.0, 0.001) = 3.915;

// Sun and Moon Horizon fade parameters
uniform bool enable_horizon_fade = true;
uniform float horizon_fade_size = 0.2;
uniform float horizon_fade_blend = 0.1;

// Day Background Colors
uniform vec4 day_bottom_color : source_color = vec4(0.4, 1.0, 1.0, 1.0);
uniform vec4 day_top_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);

// Night Background Colors
uniform vec4 night_bottom_color : source_color = vec4(0.0, 0.0, 0.2, 1.0);
uniform vec4 night_top_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

// stars
uniform sampler2D stars_texture : hint_default_black;
uniform sampler2D base_noise : hint_default_black;
uniform float stars_speed : hint_range(0.0, 1.0, 0.001) = 0.2;
uniform float stars_cutoff : hint_range(0.0, 1.0, 0.001) = 0.702;
uniform vec4 stars_sky_color : source_color = vec4(0.0, 0.11, 0.05, 1);
uniform float offset_stars : hint_range(-2.0, 2.0, 0.001) = 0.083;
uniform float stars_intensity : hint_range(-10.0, 10.0, 0.001) = -2.829;
uniform float star_falloff : hint_range(1.0, 10.0, 0.001) = 1.79;

// Cloud stuff
uniform sampler2D cloud_noise1 : hint_default_black;
uniform sampler2D cloud_noise2 : hint_default_black;
uniform vec4 cloud_edge_day_color : source_color = vec4(0.9, 0.9, 0.9, 1.0);
uniform vec4 cloud_main_day_color : source_color = vec4(1.0);
uniform vec4 cloud_edge_night_color : source_color = vec4(0.15, 0.19, 0.25, 1.0);
uniform vec4 cloud_main_night_color : source_color = vec4(0.15, 0.16, 0.20, 1.0);
uniform float cloud_speed_1 = 0.01;
uniform float cloud_speed_2 = 0.02;
uniform float cloud_speed_3 = 0.02;
uniform float cloud_scale_1 = 0.425;
uniform float cloud_scale_2 = 0.074;
uniform float cloud_scale_3 = 0.075;
uniform float cloud_distortion = 1.95;
uniform float cloud_strength = 1.0;
uniform float cloud_cutoff = 0.013;
uniform float cloud_fuzziness = 0.261;

void sky() {
	// get skyUV to place the sun and the moon
	vec2 skyUV = EYEDIR.xz / EYEDIR.y;
	
	// Unused variable? Removing this unneccessary texture sample
//	float base_n = texture(base_noise, (skyUV - TIME) * base_noise_scale).x;
	
	// get the middle -> abs of the EYEDIR to get the horizon
	float horizon = abs((EYEDIR.y * horizon_intensity) - offset_horizon);
	vec3 horizonGlow = clamp((1.0 - horizon * 5.0) * clamp(LIGHT0_DIRECTION.y * 10.0, 0.0, 1.0), 0.0, 1.0) * horizon_color_day.rgb;// 
	vec3 horizonGlowNight = clamp((1.0 - horizon * dark_falloff) * clamp( - LIGHT0_DIRECTION.y * 10.0, 0.0, 1.0), 0.0, 1.0) * horizon_color_night.rgb;//
	horizonGlow += horizonGlowNight;
	
	// horizon glow / sunset/ -rise
	float sunset = clamp((1.0 - horizon) * clamp(LIGHT0_DIRECTION.y * 5.0, 0.0, 1.0), 0.0, 1.0);
	vec3 sunsetColoured = sunset * sun_set.rgb;
	
	// sun creation
	float sun = distance(EYEDIR.xyz, LIGHT0_DIRECTION);
	float sunDisc = 1.0 - clamp(sun / sun_radius, 0.0, 1.0);
	
	// option to render flat sun
//	if (flat_sun == true) {
//		sunDisc = roundEven(sunDisc);
//	}
	// The if statement above is technically part of a single GPU wavefront cycle,
	// So its a special case where using an if statement doesn't cost too much perf
	// But using a lerp/mix looks cooler ;)
	// ...and might be slightly faster too ig, not by much tho
	sunDisc = mix(sunDisc, roundEven(sunDisc), float(flat_sun));
	
	// moon creation
	float moon = distance(EYEDIR.xyz, - LIGHT0_DIRECTION);
	float crescentMoon = distance(vec3(EYEDIR.x + moon_crescent, EYEDIR.yz), - LIGHT0_DIRECTION);
	float crescentMoonDisc = 1.0 - (crescentMoon / moon_radius);
	crescentMoonDisc = clamp(crescentMoonDisc * 50.0, 0.0, 1.0);
	float moonDisc = 1.0 - (moon / moon_radius);
	moonDisc = clamp(moonDisc * 50.0, 0.0, 1.0);
	moonDisc = clamp(moonDisc - crescentMoonDisc, 0.0, 1.0);
	
	// combine sun and moon
	float top_mask = step(0.0, EYEDIR.y) * horizon;
	top_mask = smoothstep(horizon_fade_size, horizon_fade_size + horizon_fade_blend, top_mask);
	top_mask = mix(1.0, top_mask, float(enable_horizon_fade));
	vec3 sunAndMoon = (sunDisc * sun_color.rgb) + (moonDisc * moon_color.rgb);
	sunAndMoon *= top_mask;
	
	// stars
	float stars_falloff = abs((EYEDIR.y * stars_intensity) - offset_stars) * top_mask * star_falloff;
	vec3 stars = texture(stars_texture, (skyUV * stars_falloff) + (stars_speed * (TIME / 30.0))).rgb;
	stars *= clamp(-LIGHT0_DIRECTION.y, 0, 1.0);
	stars = step(stars_cutoff, stars);
	stars += stars_sky_color.rgb;

	//Sky Background Gradient 
	// day color gradient
	vec3 gradientDay = mix(day_bottom_color.rgb, day_top_color.rgb, clamp(EYEDIR.y, 0.0, 1.0));
	// night color gradient
	vec3 gradientNight = mix(night_bottom_color.rgb, night_top_color.rgb, clamp(EYEDIR.y, 0.0, 1.0));
	vec3 skyGradients = mix(gradientNight, gradientDay, clamp(LIGHT0_DIRECTION.y, 0.0, 1.0));
	
	vec3 sky = skyGradients + sunAndMoon + sunsetColoured + stars + horizonGlow;
	
	
	// Clouds
	// UV space illusion
	// (I have no idea how MinionsArt learned how to do this but its amazing)
	vec2 cloud_uv = EYEDIR.xz / EYEDIR.y;
	// Sample Noise at different levels
	float bn = texture(base_noise, (cloud_uv - TIME * cloud_speed_1) * cloud_scale_1).r;
	float cn1 = texture(cloud_noise1, ((cloud_uv + bn * cloud_distortion) - TIME * cloud_speed_2) * cloud_scale_2).r;
	float cn2 = texture(cloud_noise2, ((cloud_uv + cn1 * cloud_strength) - TIME * cloud_speed_3) * cloud_scale_3).r;
	// Combine noise and chop it up
	float fc = clamp(cn1 * cn2, 0.0, 1.0) * clamp(EYEDIR.y, 0.0, 1.0);
	float cc = smoothstep(cloud_cutoff, cloud_cutoff + cloud_fuzziness, fc);
	// Mix colors according to time of day
	vec4 cloud_color_day = mix(cloud_edge_day_color, cloud_main_day_color, cc);
	vec4 cloud_color_night = mix(cloud_edge_night_color, cloud_main_night_color, cc);
	float linear_day_to_night = LIGHT0_DIRECTION.y * 0.5 + 0.5;
	vec4 cloud_color = mix(cloud_color_night, cloud_color_day, linear_day_to_night);
	
	COLOR = mix(sky, cloud_color.rgb, cc * cloud_color.a);
}
