#version 330 compatibility

in vec2 texCoord;

uniform sampler2D colortex0;  // The main color buffer
uniform sampler2D depthtex0;


layout(location = 0) out vec4 fragColor;

// Function to return the pixel pattern based on luminance level
int[8] getPattern(float luminance) {
    // Define a set of patterns for different luminance levels
    if (luminance > 0.9) {
        return int[8](0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF); // FULL
    } else if (luminance > 0.8) {
        return int[8](0xFF, 0x90, 0x60, 0xB8, 0x88, 0x70, 0x00, 0x00); //@
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
        return int[8](0x00, 0x00, 0xF8, 0x00, 0x00, 0x00, 0x00, 0x00); // -
    } else if (normalizedAngle >= 0.3927 && normalizedAngle < 1.1781) {
        // Around 45° ('/')
        return int[8](0x80, 0x40, 0x20, 0x10, 0x08, 0x00, 0x00, 0x00); // /
    } else if (normalizedAngle >= 1.1781 && normalizedAngle < 1.9635) {
        // Around 90° (vertical '|')
        return int[8](0x20, 0x20, 0x20, 0x20, 0x20, 0x00, 0x00, 0x00); // |
    } else if (normalizedAngle >= 1.9635 && normalizedAngle < 2.7489) {
        // Around 135° ('\')
        return int[8](0x08, 0x10, 0x20, 0x40, 0x80, 0x00, 0x00, 0x00); // \
    } else if (normalizedAngle >= 2.7489 && normalizedAngle < 3.5343) {
        // Around 180° again (horizontal '-')
        return int[8](0x00, 0x00, 0xF8, 0x00, 0x00, 0x00, 0x00, 0x00); // -
    } else if (normalizedAngle >= 3.5343 && normalizedAngle < 4.3197) {
        // Around 225° ('/')
        return int[8](0x80, 0x40, 0x20, 0x10, 0x08, 0x00, 0x00, 0x00); // /
    } else if (normalizedAngle >= 4.3197 && normalizedAngle < 5.1051) {
        // Around 270° (vertical '|')
        return int[8](0x20, 0x20, 0x20, 0x20, 0x20, 0x00, 0x00, 0x00); // |
    } else if (normalizedAngle >= 5.1051 && normalizedAngle < 5.8905) {
        // Around 315° ('\')
        return int[8](0x08, 0x10, 0x20, 0x40, 0x80, 0x00, 0x00, 0x00); // \
    } else {
        return int[8](0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00);
    }
}

// Function to apply a Gaussian blur
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

// Function to compute the Difference of Gaussians (DoG)
vec4 differenceOfGaussians(sampler2D tex, vec2 texCoord) {
    vec4 blurred1 = gaussianBlur(tex, texCoord, 1.0); // σ1 = 1.0
    vec4 blurred2 = gaussianBlur(tex, texCoord, 2.0); // σ2 = 2.0
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


// Convert HSL to RGB
vec3 hslToRgb(vec3 hsl) {
    vec3 rgb = clamp(abs(mod(hsl.x * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
    return hsl.z + (hsl.y - hsl.z) * rgb;
}

void main() {
    /*
    vec2 resolution = textureSize(colortex0, 0);
    // Calculate the size of one artificial pixel (8x8 block)
    vec2 pixelSize = 1.0 / vec2(resolution) * 8.0;

    // Determine the 8x8 block position in the screen
    vec2 blockCoords = floor(texCoord / pixelSize) * pixelSize;

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

    // Get the pixel pattern for the current luminance
    int[8] pattern = getPattern(averageLuminance);

    // Determine the position within the 8x8 block
    vec2 blockPosition = mod(texCoord / pixelSize, vec2(1.0));
    ivec2 pixelCoords = ivec2(floor(blockPosition * 8.0)); // Position within the 8x8 block

    // Check if the current pixel should be lit up according to the pattern
    bool litUp = (pattern[pixelCoords.y] & (1 << (7 - pixelCoords.x))) != 0;

    if (litUp) {
        fragColor = vec4(1.0, 1.0, 1.0, 1.0); // White for lit pixels
        //fragColor = texture(colortex0, blockCoords) * 2;
    } else {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0); // Black for unlit pixels
    }
    *//////////////////////////////////////////////////////////////////////////////
      vec2 resolution = textureSize(colortex0, 0);
      // Calculate the size of one artificial pixel (8x8 block)
      vec2 pixelSize = 1.0 / vec2(resolution) * 8.0;

      // Determine the 8x8 block position in the screen
      vec2 blockCoords = floor(texCoord / pixelSize) * pixelSize;

      vec4 colorDepth = texture(depthtex0, texCoord);
      float avg = 1 - ((colorDepth.r + colorDepth.r + colorDepth.r) / 3);
      vec4 colorDepthAjusted = vec4(avg,avg,avg,1) * 20;


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

      for (int i = 0; i < 9; ++i) {
          vec4 texColor = textureOffset(depthtex0, texCoord, offsets[i]);
          float intensity = (texColor.r + texColor.r + texColor.r) / 3 * 99999; // Assuming grayscale image, otherwise use `vec3` and average color channels
          gradX += intensity * sobelX[i / 3][i % 3];
          gradY += intensity * sobelY[i / 3][i % 3];
      }

      // Compute gradient magnitude and angle
      float magnitude = length(vec2(gradX, gradY));
      float angle = atan(gradY, gradX); // atan(y, x) gives the angle in radians

      // If magnitude is very small, no edge is detected
      if (magnitude < 100) {
          fragColor = vec4(0.0, 0.0, 0.0, 1.0); // Black
      } else {
          // Map angle to color
          vec3 color = angleToColor(angle);

          // Convert from HSL to RGB
          //color = hslToRgb(vec3(color.r, 1.0, 0.5)); // Saturation and lightness for better visibility

          // Output the color based on the gradient magnitude
          fragColor = vec4(color, 1.0);
      }

}