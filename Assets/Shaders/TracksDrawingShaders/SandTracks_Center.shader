// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Mata/visual_effect/SandTracks_Center"
{
	// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
	// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
	//test for using git inside the VSC
	Properties
	{
		
		
		_Tess ("Tessellation", Range(1, 1024)) = 256
		_Displacement ("Displacement", Range(0.0, 1.0)) = 0.25
		_SnowColor ("Snow Color", Color) = (1, 1, 1, 1)
		_SnowTex ("Snow (RGB)", 2D) = "white" { }
		_GroundColor ("Ground Color", Color) = (1, 1, 1, 1)
		_GroundTex ("Ground (RGB)", 2D) = "white" { }
		_Splat ("SplatMap", 2D) = "black" { }
		
		_MinDist ("Tessellation MinDist", Range(1, 1000)) = 3
		_MaxDist ("Tessellation MaxDist", Range(1, 1000)) = 15
		
		_Delta ("delta for computing normal for heightmap", Range(0.00001, 0.01)) = 0.0001
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 200
		
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			
			#pragma hull hull
			#pragma domain domain
			#pragma vertex tessvert
			#pragma fragment frag
			#define UNITY_PASS_FORWARDBASE
			#pragma multi_compile_fwdbase_fullshadows
			#pragma exclude_renderers gles3 metal d3d11_9x xbox360 xboxone ps3 ps4 psp2
			#pragma target 5.0
			#include "UnityCG.cginc"
			#include "desert_common.cginc"
			
			
			fixed4 frag(v2f i): COLOR
			{
				float2 splatUV = float2(0.5, 0.5) + (i.worldPos.xz - _ActorWorldPos.xy) / _SampleAreaSize;
				
				fixed3 tangleNormal = GetNormalFromHeightmap(_Splat, splatUV, _Delta, _Displacement);
				float3x3 TBN = float3x3(normalize(i.worldTangent), normalize(i.worldBitangent), normalize(i.worldNormal));
				float3x3  TBN_t = transpose(TBN);
				// fixed4 texColor = tex2D(_, i.uv);
				// fixed3 norm = UnpackNormal(tex2D(_Bump, i.uv));
				float3 worldPos = i.worldPos;
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				// //norm.y*=-1;//这个是作者实验的法线纹理是反向的，在这修正一下，正常的法线纹理需要注释掉
				fixed3 worldNormal = mul(TBN_t, tangleNormal);
				//fixed3 worldNormal = i.worldNormal;
				
				fixed  atten = LIGHT_ATTENUATION(i);
				
				fixed3 ambi = UNITY_LIGHTMODEL_AMBIENT.xyz * 1.2;
				
				fixed3 diff = _LightColor0.rgb * saturate(dot(normalize(worldNormal), normalize(lightDir)));
				
				// fixed3 lightRefl = reflect(-lightDir, worldNormal);
				// fixed3 spec = _LightColor0.rgb * pow(saturate(dot(normalize(lightRefl), normalize(worldViewDir))), _Specular) * _Gloss;
				
				// fixed3 worldView = fixed3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				// fixed3 worldRefl = reflect(-worldViewDir, worldNormal);
				
				// fixed4 fragColor;
				// fragColor.rgb = float3((ambi + (diff + spec) * atten) * texColor);
				// fragColor.a = 1.0f;
				
				return fixed4(ambi + diff * atten, 1);
			}
			
			ENDCG
			
		}
	}
	FallBack "Diffuse"
}