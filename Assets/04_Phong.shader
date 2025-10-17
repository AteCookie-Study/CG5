Shader "Unlit/04_Phong"
{
    Properties
    {
        _Color("Color", Color) = (1,0,0,1)
        _SpecularColor("Specular Color", Color) = (1,1,1,1)
        _Shininess("Shininess", Range(1, 128)) = 20
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
                o.worldPosition = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 光照方向和视线方向
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPosition);

                // 漫反射
                float diffIntensity = saturate(dot(i.normal, lightDir));
                fixed4 diffuse = _Color * diffIntensity * _LightColor0;

                // 高光反射
                float3 reflectDir = reflect(-lightDir, i.normal);
                float specIntensity = pow(saturate(dot(reflectDir, viewDir)), _Shininess);
                fixed4 specular = _SpecularColor * specIntensity * _LightColor0;

                return diffuse + specular;
            }
            ENDCG
        }
    }
}