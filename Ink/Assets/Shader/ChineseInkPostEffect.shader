Shader "Custom/ChineseInk"
{
	Properties
	{
		// original picture
		_MainTex ("MainTex", 2D) = "white" {}
	    //Gaussian blurred picture
	    _BlurTex("BlurTex",2D) = "white"{}
		//Ink screen
		_PaintTex("PaintTex",2D)="white"{}
	}
	CGINCLUDE
    #include "UnityCG.cginc"
	//depth normal map
	sampler2D _CameraDepthNormalsTexture;
    sampler2D _MainTex;
	sampler2D _BlurTex;
	sampler2D _PaintTex;
	sampler2D _NoiseTex;
	float4 _BlurTex_TexelSize;
	float4 _MainTex_ST;
	float4 _MainTex_TexelSize;
	float4 _PaintTex_TexelSize;
	float4 _offsets;
	float _EdgeWidth;
	float _Sensitive;
	int _PaintFactor;
	
	// take the gray
	float luminance(fixed3 color) {
		return 0.2125*color.r + 0.7154*color.g + 0.0721*color.b;
	}
	//Gaussian blur part
	struct v2f_blur
	{
		float2 uv : TEXCOORD0;
		float4 vertex : SV_POSITION;
		float4 uv01:TEXCOORD1;
		float4 uv23:TEXCOORD2;
		float4 uv45:TEXCOORD3;
	};

	v2f_blur vert_blur(appdata_img v)
	{
		v2f_blur o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
		_offsets *= _MainTex_TexelSize.xyxy;
		o.uv01 = v.texcoord.xyxy + _offsets.xyxy*float4(1, 1, -1, -1);
		o.uv23 = v.texcoord.xyxy + _offsets.xyxy*float4(1, 1, -1, -1)*2.0;
		o.uv45 = v.texcoord.xyxy + _offsets.xyxy*float4(1, 1, -1, -1)*3.0;
		return o;
	}

	float4 frag_blur(v2f_blur i) : SV_Target
	{
		float4 color = float4(0,0,0,0);
		color += 0.40*tex2D(_MainTex, i.uv);
		color += 0.15*tex2D(_MainTex, i.uv01.xy);
		color += 0.15*tex2D(_MainTex, i.uv01.zw);
		color += 0.10*tex2D(_MainTex, i.uv23.xy);
		color += 0.10*tex2D(_MainTex, i.uv23.zw);
		color += 0.05*tex2D(_MainTex, i.uv45.xy);
		color += 0.05*tex2D(_MainTex, i.uv45.zw);
		return color;
	}
	//Edge detection part
	struct v2f_edge{
		float2 uv:TEXCOORD0;
		float4 vertex:SV_POSITION;
	};

	v2f_edge vert_edge(appdata_img v){
		v2f_edge o;
		o.vertex = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord;
		return o;
	}

	float4 frag_edge_Roberts(v2f_edge i):SV_Target{
		//noise
		float n = tex2D(_NoiseTex,i.uv).r;
		float3 col0 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(1,0)).xyz;
		float3 col1 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(1,1)).xyz;
		float3 col2 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(0, 0)).xyz;
		float3 col3 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(0,1)).xyz;

		float3 r1 = pow(col0 - col3, 2);
		float3 r2 =  pow(col1 - col2, 2);

		float edge = luminance(r1+r2);
		edge = sqrt(edge);
		if (edge<_Sensitive)
		{
			edge = 0;
		}
		else
		{
			edge = n;
		}
		float3 color = tex2D(_BlurTex, i.uv);
		float3 finalColor = (1 - edge)*color*(0.95+0.05*n);
		float3 finalColor_test = float3(edge,edge,edge);
		return float4(finalColor, 1.0);
	}
	float4 frag_edge_Prewitt(v2f_edge i):SV_Target{
		//noise
		float n = tex2D(_NoiseTex,i.uv).r;
		float3 col0 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(0,0)).xyz;
		float3 col1 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(0,1)).xyz;
		float3 col2 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(0,2)).xyz;
		float3 col3 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(1,0)).xyz;
		float3 col4 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(1,2)).xyz;
		float3 col5 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(2,0)).xyz;
		float3 col6 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(2,1)).xyz;
		float3 col7 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(2,2)).xyz;
		
		float3 p1 = pow(col5 + col6 + col7 - col0 - col1 - col2, 2);
		float3 p2 = pow(col2 + col4 + col7 - col0 - col3 - col5, 2);

		float edge = luminance(p1 + p2);
		
		edge = sqrt(edge);
		if (edge<_Sensitive)
		{
			edge = 0;
		}
		else
		{
			edge = n;
		}
		float3 color = tex2D(_BlurTex, i.uv);
		float3 finalColor = (1 - edge)*color*(0.95+0.05*n);
		float3 finalColor_test = float3(edge,edge,edge);
		return float4(finalColor, 1.0);
	}
	float4 frag_edge_Sobel(v2f_edge i):SV_Target{
		//noise
		float n = tex2D(_NoiseTex,i.uv).r;
		float3 col0 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(0,0)).xyz;
		float3 col1 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(0,1)).xyz;
		float3 col2 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(0,2)).xyz;
		float3 col3 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(1,0)).xyz;
		float3 col4 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(1,2)).xyz;
		float3 col5 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(2,0)).xyz;
		float3 col6 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(2,1)).xyz;
		float3 col7 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(2,2)).xyz;

		float3 s1 = pow(col5 + 2*col6 + col7 - col0 - 2*col1 - col2, 2);
		float3 s2 = pow(col2 + 2*col4 + col7 - col0 - 2*col3 - col5, 2);
		float edge = luminance(s1 + s2);
		
		edge = sqrt(edge);

		if (edge<_Sensitive)
		{
			edge = 0;
		}
		else
		{
			edge = n;
		}
		float3 color = tex2D(_BlurTex, i.uv);
		float3 finalColor = (1 - edge)*color*(0.95+0.05*n);
		float3 finalColor_test = float3(edge,edge,edge);
		return float4(finalColor, 1.0);
	}
	float4 frag_edge_Frei_Chen(v2f_edge i):SV_Target{
		//noise
		float n = tex2D(_NoiseTex,i.uv).r;
		float3 col0 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(0,0)).xyz;
		float3 col1 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(0,1)).xyz;
		float3 col2 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(0,2)).xyz;
		float3 col3 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(1,0)).xyz;
		float3 col4 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(1,2)).xyz;
		float3 col5 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(2,0)).xyz;
		float3 col6 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(2,1)).xyz;
		float3 col7 = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(2,2)).xyz;
		float3 mid = tex2D(_CameraDepthNormalsTexture, i.uv + _EdgeWidth * _BlurTex_TexelSize.xy*float2(1,1)).xyz;
		float3 mask1 =  (col0 + sqrt(2)*col1 + col2 - col5 - sqrt(2)*col6 - col7) / sqrt(8);
		float3 mask2 =  (col0 + sqrt(2)*col3 + col5 - col2 - sqrt(2)*col4 - col7) / sqrt(8);
		float3 mask3 =  (sqrt(2)*col2 + col3 +  col6 - col1 - col4 - sqrt(2)*col5) / sqrt(8);
		float3 mask4 =  (sqrt(2)*col0 + col4 +  col6 - col1 - col3 - sqrt(2)*col7) / sqrt(8);
		float3 mask5 =  (col1 + col6 - col3 - col4) / 2;
		float3 mask6 =  (col2 + col5 - col0 - col7) / 2;
		float3 mask7 =  (col0 - 2*col1 + col2 - 2*col3 + 4*mid - 2*col4 + col5 - 2*col6 + col7) / 6;
		float3 mask8 =  (-2*col0 + col1 - 2*col2 + col3 + 4*mid + col4 - 2*col5 + col6 - 2*col7) / 6;
		float3 mask9 =  (col0 + col1 + col2 + col3 + mid + col4 + col5 + col6 + col7) / 3;
		float M = luminance(pow(mask1, 2) + pow(mask2, 2) + pow(mask3, 2) + pow(mask4, 2));
		float S = luminance(pow(mask1, 2) + pow(mask2, 2) + pow(mask3, 2) + pow(mask4, 2) + pow(mask5, 2) + pow(mask6, 2) + pow(mask7, 2) + pow(mask8, 2) + pow(mask9, 2));
		float edge = sqrt(M/S);
		if (edge < _Sensitive)
		{
			edge = 0;
		}
		else
		{
			edge = n;
		}
		float3 color = tex2D(_BlurTex, i.uv);
		float3 finalColor = (1 - edge)*color*(0.95+0.05*n);
		float3 finalColor_test = float3(edge,edge,edge);
		return float4(finalColor, 1.0);
	}
	// Brush filter
	struct v2f_paint {
		float2 uv:TEXCOORD0;
		float4 vertex:SV_POSITION;
	};

	v2f_paint vert_paint(appdata_img v) {
		v2f_paint o;
		o.uv = v.texcoord;
		o.vertex = UnityObjectToClipPos(v.vertex);
		return o;
	}

	float4 frag_paint(v2f_paint i):SV_Target{
		//EPF
		float3 m0 = 0.0;
		float3 m1 = 0.0;
		float3 m2 = 0.0;
		float3 m3 = 0.0;
		float3 s0 = 0.0;
		float3 s1 = 0.0;
		float3 s2 = 0.0;
		float3 s3 = 0.0;
		float3 c = 0.0;
		int radius = _PaintFactor;
		int r = (radius + 1)*(radius + 1);
		for (int j = -radius; j <= 0; ++j)
		{
			for (int k = -radius; k <= 0; ++k)
			{
				c = tex2D(_PaintTex, i.uv + _PaintTex_TexelSize.xy * float2(k, j)).xyz;
				m0 += c;
				s0 += c * c;
			}
		}
	    for (int j = 0; j <= radius; ++j)
	    {
		    for (int k = 0; k <= radius; ++k)
		    {
			    c = tex2D(_PaintTex, i.uv + _PaintTex_TexelSize.xy * float2(k, j)).xyz;
			    m1 += c;
			    s1 += c * c;
		    }
	    }
		for (int j = -radius; j <= 0; ++j)
	    {
		    for (int k = 0; k <= radius; ++k)
		    {
			    c = tex2D(_PaintTex, i.uv + _PaintTex_TexelSize.xy * float2(k, j)).xyz;
			    m2 += c;
			    s2 += c * c;
		    }
	    }
		for (int j = 0; j <= radius; ++j)
	    {
		    for (int k = -radius; k <= 0; ++k)
		    {
			    c = tex2D(_PaintTex, i.uv + _PaintTex_TexelSize.xy * float2(k, j)).xyz;
			    m3 += c;
			    s3 += c * c;
		    }
	    }
	    float4 finalFragColor = 0.;
	    float min_sigma2 = 1e+2;
	    m0 /= r;
	    s0 = abs(s0 / r - m0 * m0);
	    float sigma2 = s0.r + s0.g + s0.b;
	    if (sigma2 < min_sigma2)
	    {
		    min_sigma2 = sigma2;
		    finalFragColor = float4(m0, 1.0);
	    }


	    m1 /= r;
	    s1 = abs(s1 / r - m1 * m1);
	    sigma2 = s1.r + s1.g + s1.b;
	    if (sigma2 < min_sigma2)
	    {
		    min_sigma2 = sigma2;
		    finalFragColor = float4(m1, 1.0);
	    }


		m2 /= r;
	    s2 = abs(s2 / r - m2 * m2);
	    sigma2 = s2.r + s2.g + s2.b;
	    if (sigma2 < min_sigma2)
	    {
		    min_sigma2 = sigma2;
		    finalFragColor = float4(m2, 1.0);
	    }


		m3 /= r;
	    s3 = abs(s3 / r - m3 * m3);
	    sigma2 = s3.r + s3.g + s3.b;
	    if (sigma2 < min_sigma2)
	    {
		    min_sigma2 = sigma2;
		    finalFragColor = float4(m3, 1.0);
	    }

		return finalFragColor;
	}

	ENDCG

	SubShader
	{
		Pass
		{
			CGPROGRAM
            #pragma vertex vert_blur
            #pragma fragment frag_blur
			ENDCG
		}

		Pass
		{
			CGPROGRAM
            #pragma vertex vert_edge
            #pragma fragment frag_edge_Sobel
			ENDCG
		}

		Pass
		{
			CGPROGRAM
            #pragma vertex vert_paint
            #pragma fragment frag_paint
			ENDCG
		}
	}
}
