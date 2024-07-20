//Copyright © 2024 David Draper Jr

uniform vec3 cameraPosition;
uniform mat4 gbufferModelViewInverse; 
uniform mat4 gbufferModelView; 

varying vec2 texcoord;
varying vec2 lightcoord;

varying vec3 normal;
varying vec4 vertexColor;

varying vec4 localPos;

void main()
{
    
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;

    localPos = gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex);

    texcoord = gl_MultiTexCoord0.st;

    lightcoord = mat2(gl_TextureMatrix[1]) * gl_MultiTexCoord1.st;
    lightcoord = (lightcoord * 33.05f / 32.0f) - (1.05f / 32.0f);

    normal = gl_NormalMatrix * gl_Normal;

    vertexColor = gl_Color;

}