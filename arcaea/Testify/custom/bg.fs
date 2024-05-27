#extension GL_ARB_separate_shader_objects : enable

layout(location=1) in vec2 texVp;
layout(location=0) out vec4 target;

uniform ivec2 viewport;
uniform sampler2D bgTex;

void main()
{
    vec2 screenUV = texVp / viewport;
    vec3 col = texture(bgTex, screenUV).rgb;
    float alpha = 1.0f;
    target = vec4(col.rgb, alpha);
}
