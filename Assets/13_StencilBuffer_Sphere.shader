Shader "Unlit/Stencil_SphereBehindCube"
{
Properties
{
_MainTex("Texture", 2D) = "white" {}
_Color("Color", Color) = (1,1,1,1)
}
SubShader
{
Tags { "Queue"="Transparent+1" } // Cube 后渲染
LOD 100

    Pass
    {
        Stencil
        {
            Ref 1
            Comp Equal  // 只在 Cube 区域绘制
        }

        ZTest Always  // 不被深度挡住
        ZWrite Off
        Blend SrcAlpha OneMinusSrcAlpha

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #include "UnityCG.cginc"

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 vertex : SV_POSITION;
        };

        sampler2D _MainTex;
        float4 _MainTex_ST;
        float4 _Color;

        v2f vert(appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = TRANSFORM_TEX(v.uv, _MainTex);
            return o;
        }

        fixed4 frag(v2f i) : SV_Target
        {
            fixed4 col = tex2D(_MainTex, i.uv) * _Color;
            return col;
        }
        ENDCG
    }
}

}
