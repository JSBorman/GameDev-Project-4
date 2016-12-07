﻿

Shader "Fuse/Sprite With Fuse"
{
	Properties
	{
		[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
	_Color("Tint", Color) = (1,1,1,1)
		[MaterialToggle] PixelSnap("Pixel snap", Float) = 0
		_MinXRange("Minimum U", Range(0,1)) = 0
		_MaxXRange("Maximum U", Range(0,1)) = 1
		_FuseColor("Fuse Color", Color) = (1,1,1,1)
		_FuseCutoff("Fuse Cut Off", Range(0,1)) = 0
	}

		SubShader
	{
		Tags
	{
		"Queue" = "Transparent"
		"IgnoreProjector" = "True"
		"RenderType" = "Transparent"
		"PreviewType" = "Plane"
		"CanUseSpriteAtlas" = "True"
	}

		Cull Off
		Lighting Off
		ZWrite Off
		Blend One OneMinusSrcAlpha

		Pass
	{
		CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma multi_compile _ PIXELSNAP_ON
#pragma shader_feature ETC1_EXTERNAL_ALPHA
#include "UnityCG.cginc"

		struct appdata_t
	{
		float4 vertex   : POSITION;
		float4 color    : COLOR;
		float2 texcoord : TEXCOORD0;
	};

	struct v2f
	{
		float4 vertex   : SV_POSITION;
		fixed4 color : COLOR;
		float2 texcoord  : TEXCOORD0;
	};

	fixed4 _Color;
	fixed4 _FuseColor;
	float _FuseCutoff;
	float _MinXRange;
	float _MaxXRange;

	v2f vert(appdata_t IN)
	{
		v2f OUT;
		OUT.vertex = mul(UNITY_MATRIX_MVP, IN.vertex);
		OUT.texcoord = IN.texcoord;
		OUT.color = IN.color * _Color;
#ifdef PIXELSNAP_ON
		OUT.vertex = UnityPixelSnap(OUT.vertex);
#endif

		return OUT;
	}

	sampler2D _MainTex;
	sampler2D _AlphaTex;
	uniform float4 _MainTex_TexelSize;

	fixed4 SampleSpriteTexture(float2 uv)
	{
		fixed4 color = tex2D(_MainTex, uv);
#if ETC1_EXTERNAL_ALPHA
		// get the color from an external texture (usecase: Alpha support for ETC1 on android)
		color.a = tex2D(_AlphaTex, uv).r;
#endif //ETC1_EXTERNAL_ALPHA

		return color;
	}

	float InverseLerp(float min, float max, float middle)
	{
		return (middle - min) / (max - min);
	}

	fixed4 frag(v2f IN) : SV_Target
	{
		fixed4 c = SampleSpriteTexture(IN.texcoord);

	// Fill right
	if (InverseLerp(_MinXRange, _MaxXRange, IN.texcoord.x) < _FuseCutoff) {
		c *= _FuseColor;
	}
	else {
		c *= IN.color;
	}
	c.rgb *= c.a;
	return c;
	}
		ENDCG
	}
	}
}