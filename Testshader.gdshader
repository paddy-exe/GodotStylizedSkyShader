shader_type sky;
render_mode use_half_res_pass;

// Stars
uniform sampler2D stars_tex : hint_black;
uniform float stars_cutoff : hint_range(0.0, 1.0, 0.1) = 0.08;
uniform float stars_speed : hint_range(0.0, 1.0, 0.1) = 0.3;
uniform vec4 stars_sky_color : hint_color = vec4(0.0,0.2,0.1,1);

// Horizon
uniform float offset_horizon : hint_range(-1.0, 1.0, 0.1) = 0.0;
uniform float horizon_intensity : hint_range(-30.0, 0.0, 0.1) = -3.3;
uniform vec4 sun_set : hint_color = vec4(1.0, 0.8, 1.0, 1.0);
uniform vec4 horizon_color_day : hint_color = vec4(0.0, 0.8, 1.0, 1.0);
uniform vec4 horizon_color_night : hint_color = vec4(0.0, 0.8, 1.0, 1.0);

// Sun
uniform vec4 sun_color : hint_color = vec4(1.0);
uniform float sun_radius : hint_range(0.0, 2.0, 0.1) = 0.5;

// Moon
uniform vec4 moon_color : hint_color = vec4(1.0);
uniform float moon_radius : hint_range(0.0, 2.0, 0.1) = 0.15;
uniform float moon_offset : hint_range(-1.0, 1.0, 0.1) = -0.1;

// Day Colors
uniform vec4 day_bottom_color : hint_color = vec4(0.4, 1.0, 1.0, 1.0);
uniform vec4 day_top_color : hint_color = vec4(0.0, 0.8, 1.0, 1.0);

// Main Cloud Settings
uniform sampler2D base_noise : hint_black;
uniform sampler2D distort : hint_black;
uniform sampler2D secondary_noise : hint_black;
const float base_noise_scale = 0.2; // between 0 and 1
const float distort_scale = 0.06; // between 0 and 1
const float sec_noise_scale = 0.05; //between 0 and 1
const float distortion = 0.1; // between 0 and 1
uniform float speed : hint_range(0.0, 10.0, 0.1) = 1.4;
const float cloud_cutoff = 0.3; //between 0 and 1
const float fuzziness = 0.04; // between 0 and 1
const float fuzziness_under = 0.01; // between 0 and 1
uniform bool FUZZY = true;

// Day Cloud Settings
uniform vec4 cloud_color_day_edge : hint_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 cloud_color_day_main : hint_color = vec4(0.8, 0.9, 0.8, 1.0);
uniform vec4 cloud_color_day_under : hint_color = vec4(0.6, 0.7, 0.6, 1.0);
uniform float brightness : hint_range(0.0, 10.0, 0.1) = 2.5;

// Night Colors
uniform vec4 night_bottom_color : hint_color = vec4(0.0, 0.0, 0.2, 1.0);
uniform vec4 night_top_color : hint_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform vec4 cloud_color_night_edge : hint_color = vec4(0.0, 1.0, 1.0, 1.0);
uniform vec4 cloud_color_night_main : hint_color = vec4(0.0, 0.2, 0.8, 1.0);
uniform vec4 cloud_color_night_under : hint_color = vec4(0.0, 0.2, 0.6, 1.0);


void sky() {
	
	float horizon = abs((EYEDIR.y * horizon_intensity) - offset_horizon);
	
	vec2 skyUV = EYEDIR.xz / EYEDIR.y;
	
	// clouds
	// moving clouds
	float baseNoise = texture(base_noise, (skyUV - TIME) * base_noise_scale).x;
	
	float noise1 = texture(distort, ((skyUV + baseNoise) - (TIME * speed)) * distort_scale).r;
	float noise2 = texture(secondary_noise, ((skyUV + (noise1 * distortion)) - (TIME * (speed * 0.5))) * sec_noise_scale).r;
	float finalNoise = clamp(noise1 * noise2, 0.0, 1.0) * 3.0 * clamp(EYEDIR.y, 0.0, 1.0);
	
	if (AT_HALF_RES_PASS) {
	
		float clouds;
		float cloudsunder;
		
		if (FUZZY) {
			clouds = clamp(smoothstep(cloud_cutoff * baseNoise, cloud_cutoff * baseNoise + fuzziness, finalNoise), 0.0, 1.0);
			cloudsunder = clamp(smoothstep(cloud_cutoff* baseNoise, cloud_cutoff * baseNoise + fuzziness_under + fuzziness, noise2) * clouds, 0.0, 1.0);
		} else {
			clouds = clamp(smoothstep(cloud_cutoff, cloud_cutoff + fuzziness, finalNoise), 0.0, 1.0);
			cloudsunder = clamp(smoothstep(cloud_cutoff, cloud_cutoff + fuzziness + fuzziness_under , noise2) * clouds, 0.0, 1.0);
		}
		
		vec3 cloudsColored = mix(cloud_color_day_edge.rgb, mix(cloud_color_day_under.rgb, cloud_color_day_main.rgb, cloudsunder), clouds) * clouds;
		vec3 cloudsColoredNight = mix(cloud_color_night_edge.rgb, mix(cloud_color_night_under.rgb, cloud_color_night_main.rgb , cloudsunder), clouds) * clouds;
		cloudsColoredNight *= horizon;
		
		
		cloudsColored = mix(cloudsColoredNight, cloudsColored, clamp(LIGHT0_DIRECTION.y, 0.0, 1.0)); // lerp the night and day clouds over the light direction
		cloudsColored += (brightness * cloudsColored * horizon); // add some extra brightness

		float cloudsNegative = (1.0 - clouds) * horizon;
		
		
		//stars
		vec3 stars = texture(stars_tex, skyUV + (stars_speed * TIME)).rgb;
		stars *= clamp(-LIGHT0_DIRECTION.y, 0.0, 1.0);
		stars = step(stars_cutoff, stars);
		stars += (baseNoise * stars_sky_color).rgb;
		stars *= cloudsNegative;
		
		COLOR = stars + cloudsColored;
		
	} else {
	
		// sun creation
		float sun = distance(EYEDIR.xyz, LIGHT0_DIRECTION);
		float sunDisc = 1.0 - clamp(sun / sun_radius, 0.0, 1.0);
		
		
		// moon creation
		float moon = distance(EYEDIR.xyz, - LIGHT0_DIRECTION);
		float crescentMoon = distance(vec3(EYEDIR.x + moon_offset, EYEDIR.yz), - LIGHT0_DIRECTION);
		float crescentMoonDisc = 1.0 - (crescentMoon / moon_radius);
		crescentMoonDisc = clamp(crescentMoonDisc * 50.0, 0.0, 1.0);
		float moonDisc = 1.0 - (moon / moon_radius);
		moonDisc = clamp(moonDisc * 50.0, 0.0, 1.0);
		moonDisc = clamp(moonDisc - crescentMoonDisc, 0.0, 1.0);
		
		vec3 sunAndMoon = (sunDisc * sun_color.rgb) + (moonDisc * moon_color.rgb);
		
		// day color gradient
		vec3 gradientDay = mix(day_bottom_color.rgb, day_top_color.rgb, clamp(EYEDIR.y, 0.0, 1.0));
		// night color gradient
		vec3 gradientNight = mix(night_bottom_color.rgb, night_top_color.rgb, clamp(EYEDIR.y, 0.0, 1.0));
		vec3 skyGradients = mix(gradientNight, gradientDay, clamp(LIGHT0_DIRECTION.y, 0.0, 1.0));
		
		
		// horizon glow / sunset/rise
		float sunset = clamp((1.0 - horizon) * clamp(LIGHT0_DIRECTION.y * 5.0, 0.0, 1.0), 0.0, 1.0);
		vec3 sunsetColoured = sunset * sun_set.rgb;
		
		
		vec3 horizonGlow = clamp((1.0 - horizon * 5.0) * clamp(LIGHT0_DIRECTION.y * 10.0, 0.0, 1.0), 0.0, 1.0) * horizon_color_day.rgb;// 
		vec3 horizonGlowNight = clamp((1.0 - horizon * 5.0) * clamp( - LIGHT0_DIRECTION.y * 10.0, 0.0, 1.0), 0.0, 1.0) * horizon_color_night.rgb;//
		horizonGlow += horizonGlowNight;
		
		vec3 combined = skyGradients + sunAndMoon + sunsetColoured + horizonGlow + HALF_RES_COLOR.rgb;
		
		COLOR = combined;
	
	}
	
}