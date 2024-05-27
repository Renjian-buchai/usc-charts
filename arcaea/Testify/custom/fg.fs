#extension GL_ARB_separate_shader_objects : enable

layout(location=1) in vec2 texVp;
layout(location=0) out vec4 target;

//Const Properties
const float EffectYOffset = 0.15f;
const int Samples = 64;

//Properties
uniform float EffectStrength = 0.3f;
uniform sampler2D texFrameBuffer;

uniform ivec2 viewport;

float easeFunc(float x)
{
    if (x == 0.0f)
    {
        return 0.0f;
    }
    else
    {
        return pow(x, 1.5f);
    }
}

vec4 chromaticAberrationWithBlur(sampler2D inTexture, vec2 texUV, vec2 colOffset)
{
    vec4 flatTexture = texture(inTexture, texUV);
    vec4 blurCol = vec4(0.0f);
    
    for (int i = 1; i <= Samples/2; i++)
    {
		
		vec2 blur = float(i) / float(Samples / 2) * colOffset;
        blurCol += vec4(
        texture(inTexture, texUV + blur).r,
        texture(inTexture, texUV + colOffset * 0.75 + blur).g,
        texture(inTexture, texUV - colOffset * 0.75 + blur).b,
        flatTexture.a);
        blurCol += vec4(
        texture(inTexture, texUV - blur).r,
        texture(inTexture, texUV + colOffset * 0.75 - blur).g,
        texture(inTexture, texUV - colOffset * 0.75 - blur).b,
        flatTexture.a);
    }
    
    return clamp(blurCol / float(Samples), 0.0f, 1.0f);
}

void main()
{
    vec2 uv = vec2(texVp.x / viewport.x, 1-texVp.y / viewport.y);
    float screenRatio = viewport.x / viewport.y;
    vec2 focalUV = (uv - vec2(0.5f, 0.5f + EffectYOffset)) * vec2(screenRatio, 1);
    vec2 direction = normalize(focalUV);
    float strength = easeFunc(length(focalUV));
    
    //target = vec4(uv, 0, 1);
    target = chromaticAberrationWithBlur(texFrameBuffer, uv, direction * strength * EffectStrength);
}

