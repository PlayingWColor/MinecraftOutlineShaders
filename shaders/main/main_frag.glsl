//Copyright © 2024 David Draper Jr

/* GAUX1FORMAT:RGBA32F */  

#define MODE 1 //[1 2 3]

varying vec2 texcoord;
varying vec2 lightcoord;

varying vec3 normal;
varying vec4 vertexColor;

varying vec4 localPos;

uniform sampler2D texture;

#if MODE == 2

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

#endif

void main()
{
    vec4 vertexColorLocal = vertexColor;

#if MODE == 2

    vec3 vertexHSV = rgb2hsv(vertexColorLocal.rgb);
    vertexHSV = round(vertexHSV*10.0)/10.0;
    vertexColorLocal = vec4(hsv2rgb(vertexHSV), vertexColorLocal.a);

#endif

    vec4 color = texture2D(texture, texcoord) * vertexColorLocal;
    
    /* DRAWBUFFERS:01 */
    gl_FragData[0] = color;
    gl_FragData[1] = vec4(normal*0.5+0.5,1.0);
#ifdef ENTITIES
    if(vertexColor.a < 1.0)
        return;
#endif
    /* DRAWBUFFERS:0127 */
    gl_FragData[2] = vec4(lightcoord, 0.0, 1.0);
    gl_FragData[3] = localPos*0.1;
}