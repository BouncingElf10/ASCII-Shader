#version 150 compatibility

in vec2 texCoord;

uniform sampler2D colortex0;  // The main color buffer
uniform sampler2D depthtex0;

uniform int worldTime;

uniform sampler2D DepthSampler;
uniform float near;
uniform float far;

#include "settings.glsl"

layout(location = 0) out vec4 fragColor;

// Function to return the pixel pattern based on luminance level
int[8] getPattern(float luminance) {
    // Define a set of patterns for different luminance levels
    if (luminance > 0.9) {
        return int[8](0xF8, 0xF8, 0xF8, 0xF8, 0xF8, 0x00, 0x00, 0x00); // FULL
    } else if (luminance > 0.8) {
        return int[8](0x70, 0x90, 0x60, 0xB8, 0x88, 0x70, 0x00, 0x00); //@
    } else if (luminance > 0.7) {
        return int[8](0x20, 0x00, 0x38, 0x08, 0x70, 0x00, 0x00, 0x00); //?
    } else if (luminance > 0.6) {
        return int[8](0xF0, 0x90, 0x90, 0x90, 0xF0, 0x00, 0x00, 0x00); //O
    } else if (luminance > 0.5) {
        return int[8](0x80, 0x80, 0xF0, 0x90, 0xF0, 0x00, 0x00, 0x00); //P
    } else if (luminance > 0.4) {
        return int[8](0x70, 0x50, 0x70, 0x00, 0x00, 0x00, 0x00, 0x00); //o
    } else if (luminance > 0.3) {
        return int[8](0x70, 0x40, 0x70, 0x00, 0x00, 0x00, 0x00, 0x00); //c
    } else if (luminance > 0.2) {
        return int[8](0x20, 0x20, 0x00, 0x20, 0x00, 0x00, 0x00, 0x00); //i
    } else if (luminance > 0.1) {
        return int[8](0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00); //.
    } else {
        return int[8](0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00); // NOTHING
    }
}

// Function to return the pixel pattern based on luminance level
int[8] getPatternAngle(float angle) {
    float normalizedAngle = mod(angle, 3.14159265 * 2.0);
    if (normalizedAngle < 0.3927 || normalizedAngle > 5.8905) {
        // Around 0° or 180° (horizontal '-')
        return int[8](0x20, 0x20, 0x20, 0x20, 0x20, 0x00, 0x00, 0x00); // |
    } else if (normalizedAngle >= 0.3927 && normalizedAngle < 1.1781) {
        // Around 45° ('/')
        return int[8](0x80, 0x40, 0x20, 0x10, 0x08, 0x00, 0x00, 0x00); // /
    } else if (normalizedAngle >= 1.1781 && normalizedAngle < 1.9635) {
        // Around 90° (vertical '|')
        return int[8](0x00, 0x00, 0xF8, 0x00, 0x00, 0x00, 0x00, 0x00); // -
    } else if (normalizedAngle >= 1.9635 && normalizedAngle < 2.7489) {
        // Around 135° ('\')
        return int[8](0x08, 0x10, 0x20, 0x40, 0x80, 0x00, 0x00, 0x00); // \
    } else if (normalizedAngle >= 2.7489 && normalizedAngle < 3.5343) {
        // Around 180° again (horizontal '-')
        return int[8](0x20, 0x20, 0x20, 0x20, 0x20, 0x00, 0x00, 0x00); // |
    } else if (normalizedAngle >= 3.5343 && normalizedAngle < 4.3197) {
        // Around 225° ('/')
        return int[8](0x80, 0x40, 0x20, 0x10, 0x08, 0x00, 0x00, 0x00); // /
    } else if (normalizedAngle >= 4.3197 && normalizedAngle < 5.1051) {
        // Around 270° (vertical '|')
        return int[8](0x00, 0x00, 0xF8, 0x00, 0x00, 0x00, 0x00, 0x00); // -
    } else if (normalizedAngle >= 5.1051 && normalizedAngle < 5.8905) {
        // Around 315° ('\')
        return int[8](0x08, 0x10, 0x20, 0x40, 0x80, 0x00, 0x00, 0x00); // \
    } else {
        return int[8](0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF);
    }
}

// Function to apply a Gaussian blur
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

// Function to compute the Difference of Gaussians (DoG)
vec4 differenceOfGaussians(sampler2D tex, vec2 texCoord, ivec2 offset) {
    vec4 blurred1 = gaussianBlur(tex, texCoord, 1.0, offset);
    vec4 blurred2 = gaussianBlur(tex, texCoord, 2.0, offset);
    return blurred1 - blurred2;
}

// Function to map an angle to a color
vec3 angleToColor(float angle) {
    // Normalize the angle to the range [0, 2π)
    float normalizedAngle = mod(angle, 3.14159265 * 2.0);

    vec3 color;

    // Assign colors based on the angle, corresponding to different ASCII characters
    if (normalizedAngle < 0.3927 || normalizedAngle > 5.8905) {
        // Around 0° or 180° (horizontal '-')
        color = vec3(1.0, 0.0, 0.0); // Red for horizontal lines (-)
    } else if (normalizedAngle >= 0.3927 && normalizedAngle < 1.1781) {
        // Around 45° ('/')
        color = vec3(0.0, 0.0, 1.0); // Blue for '/'
    } else if (normalizedAngle >= 1.1781 && normalizedAngle < 1.9635) {
        // Around 90° (vertical '|')
        color = vec3(0.0, 1.0, 0.0); // Green for vertical lines (|)
    } else if (normalizedAngle >= 1.9635 && normalizedAngle < 2.7489) {
        // Around 135° ('\')
        color = vec3(1.0, 1.0, 0.0); // Yellow for '\'
    } else if (normalizedAngle >= 2.7489 && normalizedAngle < 3.5343) {
        // Around 180° again (horizontal '-')
        color = vec3(1.0, 0.0, 0.0); // Red for horizontal lines (-)
    } else if (normalizedAngle >= 3.5343 && normalizedAngle < 4.3197) {
        // Around 225° ('/')
        color = vec3(0.0, 0.0, 1.0); // Blue for '/'
    } else if (normalizedAngle >= 4.3197 && normalizedAngle < 5.1051) {
        // Around 270° (vertical '|')
        color = vec3(0.0, 1.0, 0.0); // Green for vertical lines (|)
    } else if (normalizedAngle >= 5.1051 && normalizedAngle < 5.8905) {
        // Around 315° ('\')
        color = vec3(1.0, 1.0, 0.0); // Yellow for '\'
    }

    return color;
}

float linearizeDepth(float depth, float near, float far) {
    float z = depth * 2.0 - 1.0; // Convert depth from [0, 1] to [-1, 1]
    return (2.0 * near * far) / (far + near - z * (far - near));
}

vec3 depthEdgeDetection(sampler2D depthtex0, vec2 texCoord, vec2 resolution, ivec2 offset) {

    float offsetX = 1.0 / resolution.x;
    float offsetY = 1.0 / resolution.y;

    // Sample depth values from neighboring pixels
    float depthCenter = linearizeDepth(textureOffset(depthtex0, texCoord, offset).r, near, far);
    float depthLeft   = linearizeDepth(textureOffset(depthtex0, texCoord + vec2(-offsetX, 0.0), offset).r, near, far);
    float depthRight  = linearizeDepth(textureOffset(depthtex0, texCoord + vec2(offsetX, 0.0), offset).r, near, far);
    float depthUp     = linearizeDepth(textureOffset(depthtex0, texCoord + vec2(0.0, offsetY), offset).r, near, far);
    float depthDown   = linearizeDepth(textureOffset(depthtex0, texCoord + vec2(0.0, -offsetY), offset).r, near, far);

    // Calculate the differences between the center pixel and the neighboring pixels
    float edgeH = abs(depthLeft - depthRight);
    float edgeV = abs(depthUp - depthDown);

    // Combine the horizontal and vertical edge detection results
    float edge = edgeH + edgeV;

    if (edge < 0) {
        edge = 0;
    }

    // Output the edge detection result as a grayscale color
    return vec3(edge);
}

vec3 colorGrad(float gray){
    vec3 darkColor = vec3(0,0,0) / 255;
    vec3 brightColor = vec3(255,255,255) / 255;
    vec3 mixedColor = mix(brightColor, darkColor, gray);

    return mixedColor;
}

void main() {

    // Define Sobel kernels
    mat3 sobelX = mat3(
        -1.0, 0.0, 1.0,
        -2.0, 0.0, 2.0,
        -1.0, 0.0, 1.0
    );

    mat3 sobelY = mat3(
        -1.0, -2.0, -1.0,
        0.0, 0.0, 0.0,
        1.0, 2.0, 1.0
    );

    // Texture coordinates offsets for the 3x3 kernel
    ivec2 offsets[9];
    offsets[0] = ivec2(-1,  1);
    offsets[1] = ivec2( 0,  1);
    offsets[2] = ivec2( 1,  1);
    offsets[3] = ivec2(-1,  0);
    offsets[4] = ivec2( 0,  0);
    offsets[5] = ivec2( 1,  0);
    offsets[6] = ivec2(-1, -1);
    offsets[7] = ivec2( 0, -1);
    offsets[8] = ivec2( 1, -1);

    // Apply Sobel kernels
    float gradX = 0.0;
    float gradY = 0.0;

    vec2 resolution = textureSize(colortex0, 0);
    // Calculate the size of one artificial pixel (8x8 block)
    vec2 pixelSize = 1.0 / vec2(resolution) * 8.0;

    // Number of samples per axis (supersampling factor)
    int samples = SUPER_SAMPLING * LINE;
    float sampleFactor = float(samples * samples);

    // Determine the starting coordinates for sampling
    vec2 blockCoords = floor(texCoord / pixelSize) * pixelSize;

    vec4 accumulatedColorDepth = vec4(0.0);
    float accumulatedGradX = 0.0;
    float accumulatedGradY = 0.0;

    int mode = MODE;

    // Supersampling loop
    for (int x = 0; x < samples; ++x) {
        for (int y = 0; y < samples; ++y) {
            // Offset within the pixel block for supersampling
            vec2 offset = vec2(x, y) / float(samples) * pixelSize;
            vec2 sampleCoords = blockCoords + offset;
            vec3 finalColor;

            if (mode == 0) {
                float depth = texture(depthtex0, texCoord).r;
                float d = linearizeDepth(depth, near, far);
                vec4 colorDepth = vec4(d, d, d,1) / 200;
                vec3 invertedColor = vec3(1.0) - colorDepth.rgb;
                vec3 finalColor = colorDepth.rgb * invertedColor.rgb;
            } else if (mode == 1) {
                finalColor = depthEdgeDetection(depthtex0, texCoord, resolution, ivec2(0,0));
            } else {
                vec4 edge = differenceOfGaussians(depthtex0, texCoord, ivec2(0,0));
                float edgeStrength = dot(edge.rgb, vec3(0.299, 0.587, 0.114));
                finalColor = vec3(edgeStrength) * 8000;
                if (finalColor.r > 0.04){
                    finalColor = vec3(1,1,1);
                }
            }

            float avg = 1.0 - ((finalColor.r + finalColor.r + finalColor.r) / 3.0);
            accumulatedColorDepth += vec4(avg, avg, avg, 1.0);

            // Apply Sobel kernels for this sample
            float gradX = 0.0;
            float gradY = 0.0;

            for (int i = 0; i < 9; ++i) {
                vec3 finalColor;
                vec4 texColor = textureOffset(depthtex0, sampleCoords, offsets[i]);
                if (mode == 0) {
                    float tC = linearizeDepth(texColor.r, near, far);
                    vec4 colorDepth = vec4(tC, tC, tC,1) / 200;
                    vec3 invertedColor = vec3(1.0) - colorDepth.rgb;
                    finalColor = colorDepth.rgb * invertedColor.rgb;
                } else if (mode == 1) {
                    finalColor = depthEdgeDetection(depthtex0, sampleCoords, resolution, offsets[i]);
                } else {
                    vec4 edge = differenceOfGaussians(depthtex0, sampleCoords, offsets[i]);
                    float edgeStrength = dot(edge.rgb, vec3(0.299, 0.587, 0.114));
                    finalColor = vec3(edgeStrength) * 8000;
                    if (finalColor.r > 0.04){
                        finalColor = vec3(1,1,1);
                    }
                }
                float intensity = finalColor.r;
                gradX += intensity * sobelX[i / 3][i % 3];
                gradY += intensity * sobelY[i / 3][i % 3];
            }

            accumulatedGradX += gradX;
            accumulatedGradY += gradY;
        }
    }

    // Average the accumulated values
    accumulatedColorDepth /= sampleFactor;
    accumulatedGradX /= sampleFactor;
    accumulatedGradY /= sampleFactor;

    // Compute gradient magnitude and angle based on averaged gradients
    float magnitude = length(vec2(accumulatedGradX, accumulatedGradY));
    float angle = atan(accumulatedGradY, accumulatedGradX);
    angle = clamp(angle, 0, 3.14159265 * 2.0);

    //////////////////

    // Calculate the average luminance of the 8x8 block
    float luminanceSum = 0.0;
    for(int x = 0; x < 8; ++x) {
        for(int y = 0; y < 8; ++y) {
            vec2 offset = vec2(x, y) * pixelSize / 8.0;
            vec4 color = texture(colortex0, blockCoords + offset);
            luminanceSum += dot(color.rgb, vec3(0.299, 0.587, 0.114)); // Calculate luminance
        }
    }
    float averageLuminance = luminanceSum / 64.0;

    float tC = linearizeDepth(texture(depthtex0, blockCoords).r, near, far);
    vec4 colorDepth = vec4(tC, tC, tC,1) / 200;
    vec3 invertedColor = vec3(1.0) - colorDepth.rgb;
    vec3 depthGradient = colorDepth.rgb * invertedColor.rgb;
    vec3 depthGradientInverted = vec3(1.0) - depthGradient.rgb;

    int[8] pattern;
    //0.017
    if (magnitude < 0.017 + (MAGNITUDE/1000)) {
        // Get the pixel pattern for the current luminance
        pattern = getPattern(averageLuminance);

    } else {
        pattern = getPatternAngle(angle);

    }


    // Determine the position within the 8x8 block
    vec2 blockPosition = mod(texCoord / pixelSize, vec2(1.0));
    ivec2 pixelCoords = ivec2(floor(blockPosition * 8.0)); // Position within the 8x8 block

    // Check if the current pixel should be lit up according to the pattern
    bool litUp = (pattern[pixelCoords.y] & (1 << (7 - pixelCoords.x))) != 0;
    if (averageLuminance < 0.1) {
        litUp = false;
    }

    if (litUp) {
        fragColor = vec4(1.0, 1.0, 1.0, 1.0); // White for lit pixels
        fragColor.rgb = mix(vec3(DARK_RED,DARK_GREEN,DARK_BLUE), vec3(LIGHT_RED, LIGHT_GREEN, LIGHT_BLUE), averageLuminance * (COLOR_THRESHOLD * 2));
        if (MIX_LUMINANCE) {
            fragColor.rgb *= pow(averageLuminance, MIX_LUMINANCE_AMOUNT);
        }

        if (FALLOFF) {
            fragColor.rgb *= pow(depthGradientInverted, vec3(FALLOFF_AMOUNT));
        }

        if (OG_COLOR) {
            fragColor.rgb = texture(colortex0, blockCoords).rgb;
        }

        //fragColor.rgb = vec3(sin(worldTime),cos(worldTime),tan(worldTime)) * (averageLuminance) * pow(depthGradientInverted, vec3(1)); //FALLOFF STREANGH
        //fragColor.rgb = vec3(0, 255, 0) / 255 * (2 * averageLuminance) * pow(depthGradientInverted, vec3(2)); //FALLOFF STREANGH
        //fragColor.rgb = colorGrad(averageLuminance);

    } else {
        fragColor.rgb = vec3(BACK_RED,BACK_GREEN,BACK_BLUE); // Black for unlit pixels
    }
    //fragColor.rgb = depthEdgeDetection(depthtex0, texCoord, resolution, ivec2(0));

}

