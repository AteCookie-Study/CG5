Shader "Unlit/14_Noise"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Density ("Noise Density", Range(1, 100)) = 10
        _NoiseStrength ("Noise Strength", Range(0,1)) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _Density;
            float _NoiseStrength;

            // -----------------------------
            // 基本随机数
            // -----------------------------
            float random(float2 fact)
            {
                return frac(sin(dot(fact, float2(12.9898, 78.233))) * 43758.5453);
            }

            // -----------------------------
            // 随机方向向量（hash vector）
            // -----------------------------
            float2 randomVec(float2 fact)
            {
                float r = random(fact) * 6.2831853; // *2PI
                return float2(cos(r), sin(r));
            }

            // -----------------------------
            // Perlin Noise（单层）
            // -----------------------------
            float PerlinNoise(float density, float2 uv)
            {
                float2 p = uv * density;
                float2 ip = floor(p);
                float2 fp = frac(p);

                float2 d00 = fp - float2(0, 0);
                float2 d01 = fp - float2(0, 1);
                float2 d10 = fp - float2(1, 0);
                float2 d11 = fp - float2(1, 1);

                float2 g00 = randomVec(ip + float2(0,0));
                float2 g01 = randomVec(ip + float2(0,1));
                float2 g10 = randomVec(ip + float2(1,0));
                float2 g11 = randomVec(ip + float2(1,1));

                float v00 = dot(g00, d00);
                float v01 = dot(g01, d01);
                float v10 = dot(g10, d10);
                float v11 = dot(g11, d11);

                float2 u = fp * fp * (3 - 2 * fp); // smoothstep

                return lerp(lerp(v00, v10, u.x),
                            lerp(v01, v11, u.x), u.y);
            }

            // -----------------------------
            // Vertex Shader
            // -----------------------------
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            // -----------------------------
            // Fragment Shader
            // -----------------------------
            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);

                // ---- 计算 Perlin Noise ----
                float noise = PerlinNoise(_Density, i.uv);
                noise = noise * 0.5 + 0.5;   // 映射到 0~1

                // ---- 应用 Noise 到颜色 ----
                col.rgb *= lerp(1.0, noise, _NoiseStrength);

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
