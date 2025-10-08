Shader "Unlit/02_Lambert" {
    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float3 normal : NORMAL;
            };

            v2f vert(appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                float intensity = saturate(dot(normalize(i.normal), _WorldSpaceLightPos0));
                fixed4 color = fixed4(1,1,1,1);
                fixed4 diffuse = color * intensity * _LightColor0;
                return diffuse;
            }
            ENDCG
        }
    }
}
