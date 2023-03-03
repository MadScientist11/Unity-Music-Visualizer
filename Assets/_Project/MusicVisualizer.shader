Shader "Unlit/MusicVisualizer"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags {}

        Pass
        {
            CGPROGRAM
            #pragma vertex vs
            #pragma fragment fs

            #include "UnityCG.cginc"
            #include "Packages/com.quizandpuzzle.shaderlib/Runtime/math.cginc"
            #include "Packages/com.quizandpuzzle.shaderlib/Runtime/sdf.cginc"

            sampler2D _MainTex;

            float _Samples[64];


            struct MeshData
            {
                float2 uv : TEXCOORD0;
                float4 vertex : POSITION;
            };

            struct Interpolators
            {
                float2 uv : TEXCOORD0;

                float4 vertex : SV_POSITION;
            };

            Interpolators vs(MeshData v)
            {
                Interpolators o;
                o.uv = v.uv;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }

            float opSmoothUnion(float d1, float d2, float k)
            {
                float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
                return lerp(d2, d1, h) - k * h * (1.0 - h);
            }

            float Segment_float(in float2 p, in float2 a, in float2 b)
            {
                float2 pa = p - a, ba = b - a;
                float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
                return length(pa - ba * h);
            }

            float sdArc(in float2 p, in float2 sc, in float ra, float rb)
            {
                // sc is the sin/cos of the arc's aperture
                p.x = abs(p.x);
                return ((sc.y * p.x > sc.x * p.y) ? length(p - sc * ra) : abs(length(p) - ra)) - rb;
            }


            float4 fs(Interpolators interpolators) : SV_Target
            {
                float2 uv = interpolators.uv;
                uv -= 0.5;
                uv.x *= 1.77;

                float size = 0.22;

                float radialGrad = sin((atan2(uv.x, uv.y) + PI) * 8) * 0.1;
                float2 rotatedUV = Rotate2D(uv, 0.015625 * 2);
                float radialGrad2 = (atan2(rotatedUV.x, rotatedUV.y) + PI) / TAU;

                float range01 = 64 / 1;
                float radial01 = radialGrad2 * range01;
                float tGrad = floor(radial01);
                float mod = fmod(radialGrad2, 0.015625);
                mod += mod * tGrad;
                float t = InverseLerp(-.5, .5, tGrad);
                int sampleIndex = Lerp(0, 8, tGrad);
                float sample = _Samples[tGrad];
                // float circl2 = sin(radialGrad2 * TAU *8 + cos(length(uv) * 100 * sample) * radialGrad);
                // float circle = CircleSDF(uv, size) - circl2 * 0.1;
                float range = 64 / TAU;
                float radial = atan2(uv.x, uv.y) * range;
                float angle = round(radial) / range;
                float2 radialUvOffset = float2(sin(angle), cos(angle)) * .3;

                float circle = Segment_float(uv - radialUvOffset, float2(0, 0), radialUvOffset * sample * 2) - .01;


                //float wave = uv.y + sin(uv.x * TAU * 10) * .1 + _Samples[sampleIndex] * 10 * (t > 0) * (t < 1);
                float circle3 = Annular(CircleSDF(uv, .48) + (sin(radialGrad2 * TAU * 32)) * .05 * sample * 2, 0.005);
                float arc = sdArc(Rotate2D(uv, PI/.8), float2(sin(PI*.75), cos(PI*.75)), 0.15 + _Samples[50] * .2, 0.005);
                float arc2 = sdArc(Rotate2D(uv, PI*2.25), float2(sin(PI*.2), cos(PI*.2)), 0.15, 0.005);
                float res = min(min(circle, circle3), min(arc, arc2));
                //float3 color = sin(radialGrad2 * TAU * 32) * .5 +.5;
                float3 color = SampleHard(res);
                return float4(color, 1);
            }
            ENDCG
        }
    }
}