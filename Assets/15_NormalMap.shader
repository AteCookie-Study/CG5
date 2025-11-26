Shader "Unlit/15_NormalMap_Phong"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalTex("Normal Map", 2D) = "bump" {}
        _AmbientColor("Ambient Color", Color) = (0.1,0.1,0.1,1)
        _DiffuseColor("Diffuse Color", Color) = (1,1,1,1)
        _SpecularColor("Specular Color", Color) = (1,1,1,1)
        _Shininess("Shininess", Range(1, 128)) = 20
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

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
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float3 tangent : TANGENT;
                float3 binormal : TEXCOORD1;
                float4 vertex : SV_POSITION;
                UNITY_FOG_COORDS(2)
            };

            sampler2D _MainTex;
            sampler2D _NormalTex;
            float4 _MainTex_ST;

            float4 _AmbientColor;
            float4 _DiffuseColor;
            float4 _SpecularColor;
            float _Shininess;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // 演示代码2 + 演示代码4
                o.normal = normalize(v.normal);
                o.tangent = normalize(v.tangent.xyz);
                o.binormal = normalize(cross(o.normal, o.tangent) * v.tangent.w * unity_WorldTransformParams.w);

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 演示代码3：从法线贴图获取法线
                float3 nMap = (tex2D(_NormalTex, i.uv).xyz) * 2 - 1;
                nMap = normalize(nMap);

                i.normal = normalize(i.normal);
                i.tangent = normalize(i.tangent);
                i.binormal = normalize(i.binormal);

                float3 lNormal = normalize(
                    i.tangent * nMap.x +
                    i.binormal * nMap.y +
                    i.normal * nMap.z
                );

                float3 wNormal = UnityObjectToWorldNormal(lNormal);

                // 演示代码1：Phong 光照
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float NdotL = saturate(dot(wNormal, lightDir));
                float3 viewDir = normalize(_WorldSpaceCameraPos - mul(unity_ObjectToWorld, float4(i.normal,0)).xyz);

                // 演示简单 Lambert + Blinn-Phong
                float3 ambient = _AmbientColor.rgb;
                float3 diffuse = _DiffuseColor.rgb * NdotL;
                float3 halfDir = normalize(lightDir + viewDir);
                float3 specular = _SpecularColor.rgb * pow(saturate(dot(wNormal, halfDir)), _Shininess);

                fixed4 col = tex2D(_MainTex, i.uv);
                fixed4 final = fixed4(col.rgb * (ambient + diffuse) + specular, col.a);

                UNITY_APPLY_FOG(i.fogCoord, final);
                return final;
            }

            ENDCG
        }
    }
}
