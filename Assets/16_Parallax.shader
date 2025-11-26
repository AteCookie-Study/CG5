Shader "Unlit/16_Parallax_Combined"
{
    Properties
    {
        _MainTex ("Albedo", 2D) = "white" {}
        _HeightTex ("Height", 2D) = "black" {}
        _ParallaxShallow ("Shallow Parallax Scale", Range(0,0.5)) = 0
        _ParallaxDeep ("Deep Parallax Scale", Range(0,0.5)) = 0.05
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

            // 顶点输入
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            // 顶点到片元结构
            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 viewDirTS : TEXCOORD1; // 切线空间视线向量
                UNITY_FOG_COORDS(2)
            };

            sampler2D _MainTex;
            sampler2D _HeightTex;
            float4 _MainTex_ST, _HeightTex_ST;
            float _ParallaxShallow, _ParallaxDeep;

            // 顶点函数
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                // 世界空间位置与视线向量
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                float3 viewDirWS = _WorldSpaceCameraPos.xyz - worldPos;

                // 构建切线空间TBN矩阵
                float3 t = normalize(mul((float3x3)unity_ObjectToWorld, v.tangent.xyz));
                float3 n = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));
                float3 b = cross(n, t) * v.tangent.w * unity_WorldTransformParams.w;
                float3x3 matTBN = float3x3(t, b, n);

                // 将视线向量转换到切线空间
                o.viewDirTS = mul(matTBN, viewDirWS);

                // UV
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);

                return o;
            }

            // 片元函数
            fixed4 frag(v2f i) : SV_Target
            {
                // 切线空间视线方向
                float3 viewDirTS = normalize(-i.viewDirTS);

                // 主贴图 UV
                float2 mainUV = i.uv * _MainTex_ST.xy + _MainTex_ST.zw;
                float2 heightUV = i.uv * _HeightTex_ST.xy + _HeightTex_ST.zw;

                // 采样高度贴图
                float height = tex2D(_HeightTex, heightUV).r;

                // 计算浅/深视差偏移
                float2 shallowOffset = viewDirTS.xy * _ParallaxShallow;
                float2 deepOffset    = viewDirTS.xy * _ParallaxDeep;

                float2 uv = mainUV + lerp(shallowOffset, deepOffset, height);

                // 采样颜色
                fixed4 col = tex2D(_MainTex, uv);

                // 雾效
                UNITY_APPLY_FOG(i.fogCoord, col);

                return col;
            }
            ENDCG
        }
    }
}
