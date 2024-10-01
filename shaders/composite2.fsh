#version 150 compatibility

in vec2 texCoord;

uniform sampler2D colortex0;
uniform vec2 resolution;

#include "settings.glsl"

layout(location = 0) out vec4 fragColor;

// Gaussian blur function
vec4 gaussianBlur(sampler2D tex, vec2 texCoord, float sigma, ivec2 offset) {
    float size = 2.0 * ceil(2.0 * sigma) + 1.0;
    vec2 texelSize = 1.0 / textureSize(tex, 0);

    vec4 color = vec4(0.0);
    float totalWeight = 0.0;

    for (float x = -size / 2.0; x <= size / 2.0; x++) {
        for (float y = -size / 2.0; y <= size / 2.0; y++) {
            float weight = exp(-(x * x + y * y) / (2.0 * sigma * sigma));
            color += textureOffset(tex, texCoord + vec2(x, y) * texelSize, offset) * weight;
            totalWeight += weight;
        }
    }

    return color / totalWeight;
}

// Tonemapping function (Reinhard)
vec3 ReinhardTonemap(vec3 color) {
    return color / (1.8 + color);
}

// Sharpening function
vec3 unsharp_mask(sampler2D tex, vec2 texCoord, float sharpness) {
    vec3 orig = texture(tex, texCoord).rgb;
    vec3 blurred = gaussianBlur(tex, texCoord, 1.0, ivec2(0, 0)).rgb;
    return orig + sharpness * (orig - blurred);
}

void main() {
    if (true) {
        vec2 resolution = textureSize(colortex0, 0);
        vec2 pixelSize = 1.0 / vec2(resolution) * 8.0;
        vec2 blockCoords = floor(texCoord / pixelSize) * pixelSize;

        vec4 originalColor = texture(colortex0, texCoord);
        vec3 combinedColor;
        if (BLOOM) {
            // Bloom pass: Gaussian blur the high-intensity pixels
            vec4 bloomColor = vec4(0.0);
            float threshold = BLOOM_THRESHOLD; // Adjust this value to control the bloom threshold
            vec3 highIntensity = max(vec3(0.0), originalColor.rgb - vec3(threshold));
            bloomColor = gaussianBlur(colortex0, texCoord, 4.0, ivec2(0, 0)); // Adjust the blur radius as needed

            // Combine the original color and the bloom color
            combinedColor = originalColor.rgb + bloomColor.rgb * BLOOM_STRENGTH; // Adjust the bloom intensity as needed
        } else {
            combinedColor = originalColor.rgb; // Adjust the bloom intensity as needed
        }
        vec3 toneMappedColor;
        if (TONEMAPPING) {
            // Tonemapping
            toneMappedColor = ReinhardTonemap(combinedColor);
        } else {
            toneMappedColor = combinedColor;
        }

        fragColor = vec4(toneMappedColor, originalColor.a);
    } else {
        fragColor = texture(colortex0, texCoord);
    }
}
