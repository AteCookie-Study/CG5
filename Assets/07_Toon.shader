Shader "Unlit/07_Toon"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Shininess("Shininess", Range(1, 128)) = 20
        _Steps("Toon Steps", Range(1, 5)) = 3 // Toon光照的色阶数
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

            sampler2D _MainTex;
            float _Shininess;
            float _Steps; // Toon光照的色阶数

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float3 worldPosition : TEXCOORD1;
                float3 normal : TEXCOORD2;
                float2 uv : TEXCOORD0;
            };

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                fixed4 texColor = tex2D(_MainTex, i.uv);

                // 光照方向和视线方向
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPosition);

                // 漫反射：使用纹理颜色作为基色
                float diffIntensity = saturate(dot(i.normal, lightDir));

                // Toon光照：将漫反射强度分为离散的几个等级
                diffIntensity = floor(diffIntensity * _Steps) / _Steps;

                fixed4 diffuse = texColor * diffIntensity * _LightColor0;

                // 高光：使用白色高光（已去掉颜色选择）
                float3 reflectDir = reflect(-lightDir, i.normal);
                float specIntensity = pow(saturate(dot(reflectDir, viewDir)), _Shininess);
                specIntensity = step(0.5, specIntensity); // Toon高光：将高光强度二值化
                fixed4 specular = fixed4(1,1,1,1) * specIntensity * _LightColor0;

                return diffuse + specular;
            }
            ENDCG
        }
    }
}