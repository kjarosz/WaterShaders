Shader "Custom/WaterShader" {
	Properties {
		_Amplitudes ("Amplitudes", Vector) = (1.0, 1.0, 1.0, 1.0)
		_Wavelengths ("Wavelengths", Vector) = (1.0, 1.0, 1.0, 1.0)
		_Speeds ("Speed", Vector) = (1.0, 1.0, 1.0, 1.0)
		_XDirections ("XDirections", Vector) = (1.0, 1.0, 1.0, 1.0)
		_ZDirections ("ZDirections", Vector) = (1.0, 1.0, 1.0, 1.0)
		_Color ("Water Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0, 1)) = 0.5
		_Metallic ("Metallic", Range(0, 1)) = 0.0
		_Tess ("Tessellation", Range(1, 32)) = 4
		_MinTessHeight ("Min Tess Height", Range(0, 1)) = 0.25
		_MaxTessHeight ("Max Tess Height", Range(1, 25)) = 15.0

	}
	SubShader {
		Tags { 
			"RenderType" = "Opaque" 
		}


		CGPROGRAM

		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf WrapLambert vertex:vert tessellate:tessDistance

		// Use shader model 5.0 target, to get nicer looking lighting
		#pragma target 5.0

		#include "UnityCG.cginc"
		#include "Tessellation.cginc"	  

		half4 LightingWrapLambert(SurfaceOutput s, half3 lightDir, half atten) {
			half NdotL = dot(s.Normal, lightDir);
			half diff = NdotL * 0.5 + 0.5;
			half4 c;
			c.rgb = s.Albedo * _LightColor0.rgb * (diff * atten);
			c.a = s.Alpha;
			return c;
		}
		
		float _Tess;
		float _MinTessHeight;
		float _MaxTessHeight;

		float4 tessDistance (appdata_base v0, appdata_base v1, appdata_base v2) {
			return _Tess; //UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, _MinTessHeight, _MaxTessHeight, _Tess);
		}

		static const float PI = 3.14159265f;

		struct VertOut 
		{
			float4 pos  : POSITION;
			float3 norm : NORMAL;
		};

		struct FragOut
		{
			half4 color : COLOR;
			float depth : DEPTH;
		};

		uniform float4 _Amplitudes;
		uniform float4 _Wavelengths;
		uniform float4 _Speeds;
		uniform float4 _XDirections;
		uniform float4 _ZDirections;
		uniform float4 _HeightMin;
		uniform float4 _HeightMax;
		uniform sampler2D _HeightMap;

		float wave(float amp, float wl, float sp, float2 dir, float2 pos)
		{
			float w = 2 * PI / wl;
			float phase = 2 * PI * sp / wl;
			return amp * sin( w * dot(normalize(dir), pos) + _Time.y * phase );
		}

		float wave_deriv(float amp, float wl, float sp, float2 dir, float2 pos)
		{
			float w = 2 * PI / wl;
			float phase = 2 * PI * sp / wl;
			return amp * w * cos (dot(dir, pos) * w + _Time.y * phase);
		}

		float wave_height(float2 pos)
		{
			return (
				wave(_Amplitudes[0], _Wavelengths[0], _Speeds[0], float2(_XDirections[0], _ZDirections[0]), pos)
			 +  wave(_Amplitudes[1], _Wavelengths[1], _Speeds[1], float2(_XDirections[1], _ZDirections[1]), pos)
			 +  wave(_Amplitudes[2], _Wavelengths[2], _Speeds[2], float2(_XDirections[2], _ZDirections[2]), pos)
			 +  wave(_Amplitudes[3], _Wavelengths[3], _Speeds[3], float2(_XDirections[3], _ZDirections[3]), pos)
			);
		}

		float map_height(float2 pos)
		{
			float4 c = tex2Dlod(_HeightMap, float4(pos, 0, 0));
			float whiteness = sqrt(c.x*c.x + c.y*c.y + c.z*c.z + c.w*c.w);
			return whiteness;
			
		}

		float3 normal(float2 pos)
		{
			float x = 0.0f;
			float y = 0.0f;
			for(int i = 0; i < 4; i++) {
				float2 normedWaveDir = normalize(float2(_XDirections[i], _ZDirections[i]));
				float deriv = wave_deriv(_Amplitudes[i], _Wavelengths[i], _Speeds[i], normedWaveDir, pos);
				x += normedWaveDir*deriv;
				y += normedWaveDir*deriv;
			}

			return float3(-x, -y, 1.0f);
		}

		void vert(inout appdata_base v) 
		{
			
			float4 pos = float4(
				v.vertex.x,
				v.vertex.y + wave_height(v.vertex.xz),
				v.vertex.z,
				v.vertex.w
			);

			float3 norm = normalize(normal(v.vertex.xz));

			v.vertex = pos;
			v.normal = norm;
		}

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		void surf(Input IN, inout SurfaceOutput o) {
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Alpha = c.a;
		}

		/*
		float4 frag(VertOut input) : COLOR
		{
			float3 light = normalize(_Color.rgb);
			float dprod = max(0.25f, dot(input.norm, light));
			return float4(
				_Color.r * dprod,
				_Color.g * dprod,
				_Color.b * dprod,
				_Color.a
			);
		}
		*/

		ENDCG
	} 
}
