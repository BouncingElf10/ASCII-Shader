#version 150 compatibility

in vec2 texCoord;

uniform sampler2D colortex0;
uniform vec2 resolution;

#include "settings.glsl"

layout(location = 0) out vec4 fragColor;

// Gaussian blur function
vec4 gaussianBlur(sampler2D tex, vec2 texCoord, float sigma) {
    float size = 2.0 * ceil(2.0 * sigma) + 1.0;
    vec2 texelSize = 1.0 / textureSize(tex, 0);

    vec4 color = vec4(0.0);
    float totalWeight = 0.0;

    for (float x = -size / 2.0; x <= size / 2.0; x++) {
        for (float y = -size / 2.0; y <= size / 2.0; y++) {
            float weight = exp(-(x * x + y * y) / (2.0 * sigma * sigma));
            color += texture(tex, texCoord + vec2(x, y) * texelSize) * weight;
            totalWeight += weight;
        }
    }

    return color / totalWeight;
}

// Sharpening function
vec3 unsharp_mask(sampler2D tex, vec2 texCoord, float sharpness) {
    vec3 orig = texture(tex, texCoord).rgb;
    vec3 blurred = gaussianBlur(tex, texCoord, 1.0).rgb;
    return orig + sharpness * (orig - blurred);
}

void main() {
    if (SHARPNESS) {
        float sharpness = SHARPNESS_STRENGTH; // Adjust the sharpness value as needed
        vec3 sharpColor = unsharp_mask(colortex0, texCoord, sharpness);

        fragColor = vec4(sharpColor, 1.0) * 1.4;
    } else {
        fragColor = texture(colortex0, texCoord);
    }

}