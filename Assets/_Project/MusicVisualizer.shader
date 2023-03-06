Shader "Unlit/MusicVisualizer"
{
    Properties
    {
        [HideInInspector] _MainTex ("Texture", 2D) = "white" {}
        _MaxAmplitude ("MaxAmplitude", Float) = 0.2
        _Strength ("Strength", Float) = 1
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
            #include "Packages/com.quizandpuzzle.shaderlib/Runtime/shaderlib.cginc"

            sampler2D _MainTex;


            #define FREQUENCY_BANDS 64
            float _Samples[FREQUENCY_BANDS];

            float _MaxAmplitude;
            float _Strength;

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
                float2 uv = AspectRatioUV(interpolators.uv - 0.5);

                float range = FREQUENCY_BANDS / TAU;
                float angle = round((atan2(uv.x, uv.y) + PI) * range) / range;
                float2 radialUvOffset = float2(sin(angle), cos(angle)) * -.3;
                
                float2 rotatedUV = Rotate2D(uv, 0.015625 * 3);
                float radialGrad01 = ((atan2(rotatedUV.x, rotatedUV.y) + PI) / TAU);

                float bandsGrad = radialGrad01 * FREQUENCY_BANDS;
                float bandIndex = floor(bandsGrad);
                float sample = min(_Samples[bandIndex] * _Strength, _MaxAmplitude);

                float bandSegment = .01 / Segment_float(uv - radialUvOffset, float2(0, 0), radialUvOffset * sample);

                float ring = .0025 / Annular(CircleSDF(uv, .48) + (sin(radialGrad01 * TAU * 32)) * .05 * sample, 0);
                float arc = .0025 / sdArc(Rotate2D(uv, PI / .8), float2(sin(PI * .75), cos(PI * .75)), 0.15 + _Samples[50] * .2,
                                  0);
                float arc2 = .0025 / sdArc(Rotate2D(uv, PI * 2.25), float2(sin(PI * .2), cos(PI * .2)), 0.15, 0);
                float res = max(bandSegment, max(arc, arc2));
                float3 color = max(res, ring);
                color = color * float3(0.9, 0.65, 0.5);
                return float4(color, 1);
            }
            ENDCG
        }
    }
}