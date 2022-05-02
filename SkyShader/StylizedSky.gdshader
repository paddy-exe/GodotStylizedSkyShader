// Shader Code origin from here: https://www.patreon.com/posts/making-stylized-27402644 by MinionsArt

shader_type sky;
render_mode use_half_res_pass;

// Horizon
uniform float offset_horizon : hint_range(-1.0, 1.0, 0.1) = 0.0;
uniform float horizon_intensity : hint_range(-10.0, 5.0, 0.001) = -3.3;
uniform vec4 sun_set : hint_color = vec4(1.0, 0.8, 1.0, 1.0);
uniform vec4 horizon_color_day : hint_color = vec4(0.0, 0.8, 1.0, 1.0);
uniform vec4 horizon_color_night : hint_color = vec4(0.0, 0.8, 1.0, 1.0);

// Sun
uniform vec4 sun_color : hint_color = vec4(1.0);
uniform float sun_radius : hint_range(0.0, 2.0, 0.001) = 0.5;
uniform bool flat_sun = true;

// Moon
uniform vec4 moon_color : hint_color = vec4(1.0);
uniform float moon_radius : hint_range(0.0, 2.0, 0.01) = 0.15;
// negative: crescent on right side
// positive: crescent on left side 
uniform float moon_crescent : hint_range(-0.3, 0.3, 0.001) = -0.3;
uniform float dark_falloff : hint_range(1.0, 6.0, 0.001) = 4.0;

// Day Background Colors
uniform vec4 day_bottom_color : hint_color = vec4(0.4, 1.0, 1.0, 1.0);
uniform vec4 day_top_color : hint_color = vec4(0.0, 0.8, 1.0, 1.0);

// Night Background Colors
uniform vec4 night_bottom_color : hint_color = vec4(0.0, 0.0, 0.2, 1.0);
uniform vec4 night_top_color : hint_color = vec4(0.0, 0.0, 0.0, 1.0);

// stars
uniform sampler2D stars_texture : hint_black;
uniform sampler2D base_noise : hint_black;
uniform float base_noise_scale : hint_range(0.0, 1.0, 0.001) = 0.2;
uniform float stars_speed : hint_range(0.0, 1.0, 0.001) = 0.3;
uniform float stars_cutoff : hint_range(0.0, 1.0, 0.001) = 0.08;
uniform vec4 stars_sky_color : hint_color = vec4(0.0, 0.2, 0.1, 1);

void sky() {
	// get skyUV to place the sun and the moon
	vec2 skyUV = EYEDIR.xz / EYEDIR.y;
	
	float base_n = texture(base_noise, (skyUV - TIME) * base_noise_scale).x;
	
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
	if (flat_sun == true) {
		sunDisc = roundEven(sunDisc);
	}
	
	// moon creation
	float moon = distance(EYEDIR.xyz, - LIGHT0_DIRECTION);
	float crescentMoon = distance(vec3(EYEDIR.x + moon_crescent, EYEDIR.yz), - LIGHT0_DIRECTION);
	float crescentMoonDisc = 1.0 - (crescentMoon / moon_radius);
	crescentMoonDisc = clamp(crescentMoonDisc * 50.0, 0.0, 1.0);
	float moonDisc = 1.0 - (moon / moon_radius);
	moonDisc = clamp(moonDisc * 50.0, 0.0, 1.0);
	moonDisc = clamp(moonDisc - crescentMoonDisc, 0.0, 1.0);
	
	// combine sun and moon
	vec3 sunAndMoon = (sunDisc * sun_color.rgb) + (moonDisc * moon_color.rgb);
	
	// stars
	vec3 stars = texture(stars_texture, skyUV + (stars_speed * (TIME / 20.0))).rgb;
	stars *= clamp(-LIGHT0_DIRECTION.y, 0.0, 1.0);
	stars = step(stars_cutoff, stars);
	stars += stars_sky_color.rgb;
	//stars += (base_n * stars_sky_color.rgb);
	
	
	//Sky Background Gradient
	// day color gradient
	vec3 gradientDay = mix(day_bottom_color.rgb, day_top_color.rgb, clamp(EYEDIR.y, 0.0, 1.0));
	// night color gradient
	vec3 gradientNight = mix(night_bottom_color.rgb, night_top_color.rgb, clamp(EYEDIR.y, 0.0, 1.0));
	vec3 skyGradients = mix(gradientNight, gradientDay, clamp(LIGHT0_DIRECTION.y, 0.0, 1.0));
	
	vec3 sky = skyGradients + sunAndMoon + sunsetColoured + stars + horizonGlow;
	
	COLOR = sky;
}
