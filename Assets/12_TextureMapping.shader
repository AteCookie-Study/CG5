Shader "Unlit/12_TextureMapping_MainSubMask"
{
Properties
{
_MainTex    ("MainTex", 2D) = "white" {}
_SubTex     ("SubTex", 2D)  = "white" {}
_MaskTex    ("MaskTex", 2D) = "black" {}
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
        sampler2D _SubTex;
        float4 _SubTex_ST;
        sampler2D _MaskTex;
        float4 _MaskTex_ST;

        v2f vert (appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = TRANSFORM_TEX(v.uv, _MainTex);
            UNITY_TRANSFER_FOG(o, o.vertex);
            return o;
        }

        fixed4 frag (v2f i) : SV_Target
        {
            // 采样主纹理和副纹理
            fixed4 mainCol = tex2D(_MainTex, i.uv);
            fixed4 subCol  = tex2D(_SubTex, i.uv);

            // 采样 Mask，用于混合
            fixed4 maskCol = tex2D(_MaskTex, i.uv);

            // 根据 Mask 的 R 通道混合 Main 和 Sub
            fixed4 col = lerp(mainCol, subCol, maskCol.r);

            // 可选裁剪（如果需要裁掉 R > 0.5 区域）
            // clip(0.5 - maskCol.r);

            // 应用雾效
            UNITY_APPLY_FOG(i.fogCoord, col);
            return col;
        }
        ENDCG
    }
}


}
