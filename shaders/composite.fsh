#version 330 compatibility

in vec2 texCoord;

uniform sampler2D colortex0; // The main color buffer

layout(location = 0) out vec4 fragColor;


void main() {
    // Get the resolution of the screen (or texture)
    vec2 resolution = textureSize(colortex0, 0);

    fragColor = texture(colortex0, texCoord);
}
