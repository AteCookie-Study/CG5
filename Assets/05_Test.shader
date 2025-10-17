Shader "Unlit/05_Test"
{
    Properties
    {
        _Color("Color", Color) = (1,0,0,1)
        _SpecularColor("Specular Color", Color) = (1,1,1,1)
        _Shininess("Shininess", Range(1, 128)) = 20

        _ToonSteps("Toon Steps", Range(1,8)) = 4
        _BandSmooth("Band Smoothness", Range(0,0.5)) = 0.08   // 0 = 硬い分離、値が大きいほど滑らかになる
        _SpecThreshold("Spec Threshold", Range(0,1)) = 0.6
        _SpecSmooth("Spec Smoothness", Range(0,0.5)) = 0.02   // ハイライトの滑らかさの幅

        _OutlineColor("Outline Color", Color) = (0,0,0,1)
        _EdgeStart("Edge Start", Range(0,1)) = 0.6
        _EdgeWidth("Edge Width (feather)", Range(0,1)) = 0.25
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            float4 _Color;
            float4 _SpecularColor;
            float _Shininess;

            float _ToonSteps;
            float _BandSmooth;
            float _SpecThreshold;
            float _SpecSmooth;

            float4 _OutlineColor;
            float _EdgeStart;
            float _EdgeWidth;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldPosition : TEXCOORD1;
                float3 normal : TEXCOORD2;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                float4 worldPos4 = mul(unity_ObjectToWorld, v.vertex);
                o.worldPosition = worldPos4.xyz;
                o.normal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));
                return o;
            }

            // 滑らかな量子化関数：各レベル間で _BandSmooth を使ってスムーズに遷移させる
            float SmoothToon(float nDotL, float steps, float bandSmooth)
            {
                steps = max(1.0, steps);
                float scaled = saturate(nDotL) * steps;
                float idx = floor(scaled);
                float frac = scaled - idx; // 0..1
                // bandSmooth が 0 の場合に除算エラーを防ぐ
                float smooth = max(1e-5, bandSmooth);
                // frac が [0, smooth] の範囲で smoothstep により 1 に遷移し、それ以外は 0 または 1 を維持
                // これにより階調の境界で柔らかな遷移を作り出す
                float t = saturate(frac / smooth);
                t = smoothstep(0.0, 1.0, t);
                return (idx + t) / steps;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 n = normalize(i.normal);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPosition);

                // ディフューズ（滑らかなトゥーン）
                float NdotL = dot(n, lightDir);
                float toonDiffuseFactor = SmoothToon(NdotL, _ToonSteps, _BandSmooth);
                fixed3 diffuse = _Color.rgb * toonDiffuseFactor * _LightColor0.rgb;

                // スペキュラー（閾値 + 滑らかな遷移）
                float3 reflectDir = reflect(-lightDir, n);
                float vdotr = saturate(dot(normalize(viewDir), normalize(reflectDir)));
                // 閾値を使用し、閾値付近で smoothstep により滑らかに遷移させる
                float specRaw = pow(vdotr, _Shininess);
                float specEdge = saturate((_SpecThreshold - vdotr) / max(1e-5, -_SpecSmooth)); // 滑らかさパラメータを計算
                float specMask = 1.0 - smoothstep(0.0, 1.0, specEdge); // 閾値付近で滑らかにハイライトを出す
                fixed3 specular = _SpecularColor.rgb * specRaw * specMask * _LightColor0.rgb;

                // 輪郭（リムライト）を柔らかく保つ
                float rim = 1.0 - saturate(dot(n, viewDir));
                float edge0 = _EdgeStart;
                float edge1 = saturate(_EdgeStart + _EdgeWidth);
                float outlineMask = smoothstep(edge0, edge1, rim);

                fixed3 lit = diffuse + specular;
                fixed3 outlineLit = _OutlineColor.rgb * _LightColor0.rgb;
                fixed3 result = lerp(lit, outlineLit, outlineMask);

                return fixed4(result, 1.0);
            }
            ENDCG
        }
    }
}
