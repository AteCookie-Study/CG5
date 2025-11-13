Shader "Unlit/11_DCM_Dissolve"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MaskTex ("Dissolve Mask", 2D) = "gray" {}     // 溶解遮罩贴图
        _Dissolve ("Dissolve Threshold", Range(0,1)) = 0.5

        _Shininess("Shininess", Range(1, 128)) = 20
        _Steps("Toon Steps", Range(1, 8)) = 3
        _BandSmooth("Band Smoothness", Range(0,0.5)) = 0.08
        _SpecularColor("Specular Color", Color) = (1,1,1,1)
        _SpecThreshold("Spec Threshold", Range(0,1)) = 0.6
        _SpecSmooth("Spec Smoothness", Range(0,0.5)) = 0.02

        _OutlineColor("Outline Color", Color) = (0,0,0,1)
        _EdgeStart("Edge Start", Range(0,1)) = 0.6
        _EdgeWidth("Edge Width (feather)", Range(0,1)) = 0.25

        _Alpha("Overall Transparency", Range(0,1)) = 1
        _Cutoff("Alpha Cutoff (for JPG)", Range(0,1)) = 0.5
        _BackColor("Backface Color", Color) = (0,0.2,1,1)   // 背面颜色（蓝）
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off // 渲染双面

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            sampler2D _MaskTex;
            float _Dissolve;

            float _Shininess;
            float _Steps;
            float _BandSmooth;
            float4 _SpecularColor;
            float _SpecThreshold;
            float _SpecSmooth;

            float4 _OutlineColor;
            float _EdgeStart;
            float _EdgeWidth;

            float _Alpha;
            float _Cutoff;
            float4 _BackColor;

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float2 uv : TEXCOORD0;
            };

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));
                o.uv = v.uv;
                return o;
            }

            float SmoothToon(float nDotL, float steps, float bandSmooth)
            {
                steps = max(1.0, steps);
                float scaled = saturate(nDotL) * steps;
                float idx = floor(scaled);
                float frac = scaled - idx;
                float smooth = max(1e-5, bandSmooth);
                float t = saturate(frac / smooth);
                t = smoothstep(0.0, 1.0, t);
                return (idx + t) / steps;
            }

            fixed4 frag (v2f i) : SV_Target {
                fixed4 texColor = tex2D(_MainTex, i.uv);
                fixed4 mask = tex2D(_MaskTex, i.uv);

                // Dissolve 丢弃像素
                clip(mask.r - _Dissolve);

                // JPG 没有 alpha，用亮度代替
                float grayscaleAlpha = dot(texColor.rgb, float3(0.299, 0.587, 0.114));
                if (grayscaleAlpha < _Cutoff) discard;

                // ======= Toon 光照 =======
                float3 n = normalize(i.normal);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos);

                float NdotL = dot(n, lightDir);
                float toonDiffuseFactor = SmoothToon(NdotL, _Steps, _BandSmooth);
                fixed3 diffuse = texColor.rgb * toonDiffuseFactor * _LightColor0.rgb;

                float3 reflectDir = reflect(-lightDir, n);
                float vdotr = saturate(dot(normalize(viewDir), normalize(reflectDir)));
                float specRaw = pow(vdotr, _Shininess);
                float specEdge = saturate((_SpecThreshold - vdotr) / max(1e-5, -_SpecSmooth));
                float specMask = 1.0 - smoothstep(0.0, 1.0, specEdge);
                fixed3 specular = _SpecularColor.rgb * specRaw * specMask * _LightColor0.rgb;

                float rim = 1.0 - saturate(dot(n, viewDir));
                float edge0 = _EdgeStart;
                float edge1 = saturate(_EdgeStart + _EdgeWidth);
                float outlineMask = smoothstep(edge0, edge1, rim);

                fixed3 lit = diffuse + specular;
                fixed3 outlineLit = _OutlineColor.rgb * _LightColor0.rgb;
                fixed3 result = lerp(lit, outlineLit, outlineMask);

                // ======= 摄像机朝向判断（正面/背面） =======
                float facing = step(0.0, dot(n, viewDir)); // 1: 正面, 0: 背面
                float3 frontColor = result;
                float3 backColor = _BackColor.rgb;
                float3 finalColor = lerp(backColor, frontColor, facing);

                return fixed4(finalColor, grayscaleAlpha * _Alpha);
            }
            ENDCG
        }
    }
}
