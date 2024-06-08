//Copyright © 2024 David Draper Jr

#version 120

varying vec2 texcoord;

uniform vec3 sunPosition;

uniform float viewWidth;
uniform float viewHeight;
uniform float sunAngle;

uniform vec3 fogColor;
uniform vec3 skyColor;

uniform ivec2 eyeBrightness;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;

uniform sampler2D depthtex0;

uniform sampler2D normals;

vec3 derivative(sampler2D tex, vec2 texCoord, vec2 resolution, float radius)
{
    vec3 center = texture2D(tex, texCoord).rgb;

    vec3 difUp = center - texture2D(tex, texCoord + vec2(0,radius)/resolution).rgb;
    vec3 difDown = center - texture2D(tex, texCoord + vec2(0,-radius)/resolution).rgb;

    vec3 difRight = center - texture2D(tex, texCoord + vec2(radius,0)/resolution).rgb;
    vec3 difLeft = center - texture2D(tex, texCoord + vec2(-radius,0)/resolution).rgb;

    return (difUp+difDown+difRight+difLeft)/4 * radius;
}

float averageRGB(vec3 color)
{
    return (color.r + color.g + color.b)/3.0;
}

float greyDerivative(sampler2D tex, vec2 texCoord, vec2 resolution, float radius, float bias)
{
    vec3 center = texture2D(tex, texCoord).rgb;

    float difUp = ceil(averageRGB(abs(center - texture2D(tex, texCoord + vec2(0,radius)/resolution).rgb)) - bias);
    float difDown = 0;//ceil(averageRGB(abs(center - texture2D(tex, texCoord + vec2(0,-radius)/resolution).rgb)) - bias);

    float difRight = ceil(averageRGB(abs(center - texture2D(tex, texCoord + vec2(radius,0)/resolution).rgb)) - bias);
    float difLeft = 0;//ceil(averageRGB(abs(center - texture2D(tex, texCoord + vec2(-radius,0)/resolution).rgb)) - bias);

    return clamp(difUp+difDown+difRight+difLeft,0,1);
}

vec3 subPixelDerivate(sampler2D tex, vec2 texCoord, vec2 resolution, float radius)
{
    vec3 center = derivative(tex, texCoord, resolution, radius);

    vec3 up = derivative(tex, texCoord + vec2(0,radius)/resolution, resolution, radius);

    vec3 down = derivative(tex, texCoord + vec2(0,radius)/resolution, resolution, radius);

    vec3 right = derivative(tex, texCoord + vec2(radius,0)/resolution, resolution, radius);

    vec3 left = derivative(tex, texCoord + vec2(-radius,0)/resolution, resolution, radius);

    return (center+up+down+right+left)/5;
}

float subPixelGreyDerivate(sampler2D tex, vec2 texCoord, vec2 resolution, float radius, float bias)
{
    float center = greyDerivative(tex, texCoord, resolution, radius, bias);

    float up = greyDerivative(tex, texCoord + vec2(0,1)/resolution, resolution, radius, bias);

    float down = greyDerivative(tex, texCoord + vec2(0,-1)/resolution, resolution, radius, bias);

    float right = greyDerivative(tex, texCoord + vec2(1,0)/resolution, resolution, radius, bias);

    float left = greyDerivative(tex, texCoord + vec2(-1,0)/resolution, resolution, radius, bias);

    return (center+up+down+right+left)/5;
}

float makeOutlines(sampler2D colorTex, sampler2D depthTex, sampler2D normalTex, vec2 texCoord, vec2 resolution)
{
    float depthDerivative = greyDerivative(depthTex, texCoord, resolution, 1, 0.001);
    float normalDerivative = greyDerivative(normalTex, texCoord, resolution, 1, 0.0000);
    float colorDerivative = greyDerivative(colorTex, texCoord, resolution, 1, 0.05);

    float combinedOutline = colorDerivative
                            +normalDerivative
                            +colorDerivative;

    return combinedOutline;
}

float antiAliasOutlines(sampler2D colorTex, sampler2D depthTex, sampler2D normalTex, vec2 texCoord, vec2 resolution)
{
    float center = clamp(makeOutlines(colortex0, depthtex0, colortex1, texcoord, resolution),0,1);

    float up = clamp(makeOutlines(colortex0, depthtex0, colortex1, texcoord + vec2(0,1)/resolution, resolution),0,1);

    float down = clamp(makeOutlines(colortex0, depthtex0, colortex1, texcoord + vec2(0,-1)/resolution, resolution),0,1);

    float right = clamp(makeOutlines(colortex0, depthtex0, colortex1, texcoord + vec2(1,0)/resolution, resolution),0,1);

    float left = clamp(makeOutlines(colortex0, depthtex0, colortex1, texcoord + vec2(-1,0)/resolution, resolution),0,1);

    return center/4+(up+down+right+left)/4;
}

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float limit_range(float dither, float value, float limit_by)
{
    return round(value * limit_by + (dither-0.5)*0.25)/limit_by;
}

void main()
{
    vec3 albedo = texture2D(colortex0, texcoord).rgb;
    float depth = texture2D(depthtex0, texcoord).r;
    vec3 normal = texture2D(colortex1, texcoord).rgb;

    float radiusFromDepth = 5 - (depth*depth) * 4;

    float combinedOutline = 1.0-antiAliasOutlines(colortex0, depthtex0, colortex1, texcoord, vec2(viewWidth, viewHeight));

    
    

    vec3 lightmap = texture2D(colortex2, texcoord).rgb;   

    vec3 skylight = lightmap.y * skyColor * 1.5 + vec3(0.4);
    vec3 torchlight = lightmap.x * vec3(0.95,0.6,0.45) * mix(6,1,skyColor.b+0.2);

    vec3 color = albedo * (skylight + torchlight);

    //vec3 colorOutlines = 0.25 * (1.0-combinedOutline) * (vec3(1.0)-color);

    if(depth == 1.0){
        gl_FragData[0] = vec4(albedo, 1.0);
        return;
    }

    /* DRAWBUFFERS:0 */
    // Finally write the diffuse color
    gl_FragData[0] = vec4((0.5+combinedOutline)*color, 1.0);
}