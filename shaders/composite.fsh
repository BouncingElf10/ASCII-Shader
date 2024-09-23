#version 430 compatibility

in vec2 texCoord;

uniform sampler2D colortex0;

layout(location = 0) out vec4 fragColor;

void main() {
    fragColor = texture(colortex0, texCoord);
    gl_FragData[2] = vec4(0,1,0,1);
}
