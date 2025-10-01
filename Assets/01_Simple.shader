Shader "Unlit/01_Simple"
{
    Properties
    {
        _Color("Color", Color) = (1,0,0,1)
    }
   
    SubShader
    {
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            fixed4 _Color;

            // Vertex Shader
            float4 vert(float4 v : POSITION) : SV_POSITION
            {
                float4 o;
                return UnityObjectToClipPos(v);
                return o;
            }

            // Fragment Shader
            fixed4 frag(float4 i : SV_POSITION) : SV_TARGET
            {
                fixed4 o = _Color;
               return o;
            }
            ENDCG
        }
    }
}
