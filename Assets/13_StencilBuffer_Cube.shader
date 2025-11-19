Shader "Unlit/Stencil_CubeTransparent"
{
SubShader
{
Tags { "Queue"="Transparent" }  // 在后面渲染
Pass
{
// Stencil 设置
Stencil
{
Ref 1           // 写入值为 1
Comp Always     // 总是写入
Pass Replace    // 将Stencil值替换为Ref
}

        // 不写深度，不挡住后面的物体
        ZWrite Off

        // 使用透明混合，不绘制颜色
        Blend SrcAlpha OneMinusSrcAlpha

        // 不输出任何颜色
        ColorMask 0

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #include "UnityCG.cginc"

        struct appdata { float4 vertex : POSITION; };
        struct v2f { float4 vertex : SV_POSITION; };

        v2f vert(appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            return o;
        }

        fixed4 frag(v2f i) : SV_Target
        {
            return fixed4(0,0,0,0); // 不输出颜色
        }
        ENDCG
    }
}

}
