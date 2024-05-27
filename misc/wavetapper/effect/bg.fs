#extension GL_ARB_separate_shader_objects : enable

layout(location=1) in vec2 texVp;
layout(location=0) out vec4 target;

void main()
{
  vec4 col = vec4(0,0,0,0);

  target = col;

}
