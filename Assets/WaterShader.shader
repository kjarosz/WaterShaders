Shader "Custom/WaterShader" {
	Properties {
		_Amplitudes ("Amplitudes", Vector) = (1.0, 1.0, 1.0, 1.0)
		_Wavelengths ("Wavelengths", Vector) = (1.0, 1.0, 1.0, 1.0)
		_Speeds ("Speed", Vector) = (1.0, 1.0, 1.0, 1.0)
		_XDirections ("XDirections", Vector) = (1.0, 1.0, 1.0, 1.0)
		_ZDirections ("ZDirections", Vector) = (1.0, 1.0, 1.0, 1.0)
		_WaterColor ("Water Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_HeightMin ("Height Min", float) = 1.0
		_HeightMax ("Height Max", float) = 1.0
		_HeightMap ("Heightmap", 2D) = "defaulttexture" {}
		_CausticsColor ("Caustics Color", Color) = (1.0, 1.0, 1.0, 1.0)
	}
	SubShader {
		Tags { 
			"QueueType" = "Transparent"
			"RenderType" = "Transparent" 
		}

		Blend SrcAlpha OneMinusSrcAlpha
		Lighting on

		Pass {
			CGPROGRAM

			// Physically based Standard lighting model, and enable shadows on all light types
			#pragma vertex vert
			#pragma fragment frag

			// Use shader model 3.0 target, to get nicer looking lighting
			#pragma target 3.0

			#include "UnityCG.cginc"	  
			
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
			uniform float4 _WaterColor;
			uniform float4 _HeightMin;
			uniform float4 _HeightMax;
			uniform sampler2D _HeightMap;

			float wave(float amp, float wl, float sp, float2 dir, float2 pos)
			{
				float w = 2 * PI / wl;
				float phase = 2 * PI * sp / wl;
				return amp * sin( w * dot(dir, pos) + _Time.y * phase );
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
				) / 4.0f;
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
					float deriv = wave_deriv(_Amplitudes[i], _Wavelengths[i], _Speeds[i], float2(_XDirections[i], _ZDirections[i]), pos);
					x += _XDirections*deriv;
					y += _ZDirections*deriv;
				}

				return float3(-x, -y, 1.0f);
			}

			VertOut vert(appdata_base v) 
			{
				VertOut output;
				output.pos = mul(UNITY_MATRIX_MVP, float4(
					v.vertex.x,
					v.vertex.y + wave_height(v.vertex.xz),
					v.vertex.z,
					v.vertex.w
				));

				output.norm = normalize(normal(v.vertex.xz));

				return output;
			}

			float4 frag(VertOut input) : COLOR
			{
				float3 light = normalize(_WaterColor.rgb);
				float dprod = max(0.5f, dot(input.norm, light));
				return float4(
					_WaterColor.r * dprod,
					_WaterColor.g * dprod,
					_WaterColor.b * dprod,
					_WaterColor.a
				);
			}

			ENDCG
		}
	} 
}
