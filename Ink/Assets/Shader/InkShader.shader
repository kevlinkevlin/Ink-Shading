Shader "Custom/InkShader"
{
    Properties
	{
		_MainTex("Main", 2D) = "white" {}
		_Thred("Edge Thred" , Range(0.01,1)) = 0.25
		_Range("Edge Range" , Range(1,10)) = 1		
		_Pow("Edge Intensity",Range(0,10))=1
		_BrushTex("Brush Texture", 2D) = "white" {}

		[Enum(Opacity,1,Darken,2,Lighten,3,Multiply,4,Screen,5,Overlay,6,SoftLight,7)]
		_BlendType("Blend Type", Int) = 7
	}
    SubShader 
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}

		// the first outline pass
		Pass 
		{
            
            CGPROGRAM
            #include "UnityCG.cginc"

            #pragma vertex vert
			#pragma fragment frag
            sampler2D  _MainTex;
            sampler2D _BrushTex;
            fixed _BlendType;
            fixed _Range;
            fixed _Thred;
            fixed _Pow;
            uniform float4 _MainTex_ST;
            struct appdata
			{
				float4 vertex : POSITION;
                float4 normal : NORMAL;
				float2 uv : TEXCOORD0;
			};
            struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
                float4 worldPos : TEXCOORD1;
                float4 vdotn : TEXCOORD2;
			};

			v2f vert(appdata v)
	        {
	        	v2f o;
	        	o.vertex = UnityObjectToClipPos(v.vertex);
	        	o.uv = TRANSFORM_TEX(v.uv, _MainTex);
	        	o.worldPos = UnityObjectToClipPos(v.vertex);
	        	float3 viewDir = normalize(mul(unity_WorldToObject, float4(_WorldSpaceCameraPos.xyz, 1)).xyz - v.vertex);
	        	o.vdotn = dot(normalize(viewDir), v.normal);
	        	return o;
	        }
            float4 frag(v2f i) : SV_TARGET
			{
				float4 mainTex = tex2D(_MainTex, i.uv);
	            float4 brushTex = tex2D(_BrushTex, i.uv);
	            float texGrey = (mainTex.r + mainTex.g + mainTex.b)*0.33;
	            texGrey = pow(texGrey, 0.3);
	            texGrey *= 1 - cos(texGrey * 3.14);
	            float brushGrey = (brushTex.r + brushTex.g + brushTex.b)*0.33;
                float blend;
	            if (_BlendType == 1)
	            	blend = texGrey * 0.5 + brushGrey * 0.5;
	            else if (_BlendType == 2)
	            	blend = texGrey < brushGrey ? texGrey : brushGrey;
	            else if (_BlendType == 3)
	            	blend = texGrey > brushGrey ? texGrey : brushGrey;
	            else if (_BlendType == 4)
	            	blend = texGrey * brushGrey;
	            else if (_BlendType == 5)
	            	blend = 1 - (1 - texGrey)*(1 - brushGrey);
	            else if (_BlendType == 6)
	            	blend = brushGrey >0.5 ? 1 - 2 * (1 - texGrey)*(1 - brushGrey) : 2 * texGrey * brushGrey;
	            else if (_BlendType == 7)
	            	blend = texGrey >0.5 ? (2 * texGrey - 1)*(brushGrey - brushGrey * brushGrey) + brushGrey : (2 * texGrey - 1)*(sqrt(brushGrey) - brushGrey) + brushGrey;
	            float4 col = float4(blend, blend, blend, 1);
                float edge = pow(i.vdotn, 1) / _Range;
	            edge = edge > _Thred ? 1 : edge;
	            edge = pow(edge, _Pow);
	            float4 edgeColor = float4(edge, edge, edge, edge);
                col = edgeColor * (1 - edgeColor.a) + col * (edgeColor.a);

				return col;
			}
            

            ENDCG
		}
    }
    fallback "Diffuse"
}
