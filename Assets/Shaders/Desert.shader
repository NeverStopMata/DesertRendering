// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Mata/Terrain/Desert"
{
	Properties
	{
		// set by terrain engine
		[HideInInspector] _Control ("Control (RGBA)", 2D) = "red" { }
		[HideInInspector] _Splat3 ("Layer 3 (A)", 2D) = "white" { }
		[HideInInspector] _Splat2 ("Layer 2 (B)", 2D) = "white" { }
		[HideInInspector] _Splat1 ("Layer 1 (G)", 2D) = "white" { }
		[HideInInspector] _Splat0 ("Layer 0 (R)", 2D) = "white" { }
		[HideInInspector] _Normal3 ("Normal 3 (A)", 2D) = "bump" { }
		[HideInInspector] _Normal2 ("Normal 2 (B)", 2D) = "bump" { }
		[HideInInspector] _Normal1 ("Normal 1 (G)", 2D) = "bump" { }
		[HideInInspector] _Normal0 ("Normal 0 (R)", 2D) = "bump" { }
		[HideInInspector] [Gamma] _Metallic0 ("Metallic 0", Range(0.0, 1.0)) = 0.0
		[HideInInspector] [Gamma] _Metallic1 ("Metallic 1", Range(0.0, 1.0)) = 0.0
		[HideInInspector] [Gamma] _Metallic2 ("Metallic 2", Range(0.0, 1.0)) = 0.0
		[HideInInspector] [Gamma] _Metallic3 ("Metallic 3", Range(0.0, 1.0)) = 0.0
		[HideInInspector] _Smoothness0 ("Smoothness 0", Range(0.0, 1.0)) = 1.0
		[HideInInspector] _Smoothness1 ("Smoothness 1", Range(0.0, 1.0)) = 1.0
		[HideInInspector] _Smoothness2 ("Smoothness 2", Range(0.0, 1.0)) = 1.0
		[HideInInspector] _Smoothness3 ("Smoothness 3", Range(0.0, 1.0)) = 1.0

		_Roughness ("Roughness", range(0, 1)) = 1
		[Space(10)]
		[Header(NormalMap)]
		_DetailNRMTexture ("detail normal texture", 2D) = "bump" { }
		
		_DetailNormalScale ("Detail Normal Scale", Range(0.0, 2.0)) = 1.0
		_NormalScale ("Normal Scale", Range(0.0, 2.0)) = 1.0
		


		[Space(10)]
		[Header(Ocean Specular)]
		_BaseRoughness ("base roughness", Range(0.0001, 1.0)) = 0.3
		_DetailRoughness ("detail roughness", Range(0.0001, 1.0)) = 0.5
		_OceanSpecularColor ("_Ocean Specular Color ", color) = (1, 1, 1, 1)
		[Space(10)]
		[Header(Glitter)]
		_GlitterTex ("Glitter Noise Map ", 2D) = "white" { }
		_Glitterness ("Glitterness ", float) = 1
		_GlitterRange ("Glitter Range ", float) = 1
		_GlitterColor ("Glitter Color ", color) = (1, 1, 1, 1)
		_GlitterMutiplyer ("Glitter Mutiplyer", float) = 1
		[Space(10)]
		[Header(nonsense)]
		_IndirectScale ("indirectScale", Range(0.0, 0.3)) = 0.15
		// used in fallback on old cards & base map
		[HideInInspector]_MainTex ("BaseMap (RGB)", 2D) = "white" { }
		[HideInInspector] _Color ("Main Color", Color) = (1, 1, 1, 1)
	}
	//
	SubShader
	{
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			
			//#pragma hull hull
			//#pragma domain domain
			//#include "Tessellation.cginc"


			#pragma multi_compile_fog
			#pragma target 5.0
			// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
			#pragma exclude_renderers gles
			
			#pragma multi_compile_fwdbase
			#pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
			//#pragma multi_compile SHADOWS_SHADOWMASK
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "TerrainSplatmapCommon.cginc"
			#include "UnityShadowLibrary.cginc"


			fixed4 _Color;
			float4 _Splat0_ST;
			float4 _Splat1_ST;
			float4 _Splat2_ST;
			float4 _Splat3_ST;
			float4 _DetailNRMTexture_ST;
			//sampler2D _Splat0;
			sampler2D _Normal0;
			sampler2D _Normal1;
			sampler2D _Normal2;
			sampler2D _Normal3;
			sampler2D _DetailNRMTexture;
			float _NormalScale;
			float _IndirectScale;
			float _BaseRoughness;
			float _DetailNormalScale;
			float _DetailRoughness;
			float _Roughness;
			float4 _OceanSpecularColor;

			float _Glitterness;
			sampler2D _GlitterTex;
			float4 _GlitterTex_ST;
			float4 _GlitterColor;
			float _GlitterRange;
			float _GlitterMutiplyer;
			// struct a2v
			// {
			// 	float4 vertex: POSITION;
			// 	float3 normal: NORMAL;
			// 	float4 tangent: TANGENT;
			// 	float2 uv: TEXCOORD0;
				
			// 	float2 uvLM_Ctrl: TEXCOORD1;  // Not prefixing '_Contorl' with 'uv' allows a tighter packing of interpolators, which is necessary to support directional lightmap.
				
			// 	UNITY_FOG_COORDS(2)
			// };
			
			struct v2f
			{
				float4 pos: SV_POSITION;
				float2 uv: TEXCOORD0;
				float2 uvLM_Ctrl: TEXCOORD1;
				float3 worldTangent: TEXCOORD2;     // tangent direction in world
				float3 worldBitangent: TEXCOORD3;   // bitangent direction in world
				float3 worldNormal: NORMAL;
				float3 worldView: TEXCOORD4;
				float3 worldPos: TEXCOORD5;
				SHADOW_COORDS(6)
				UNITY_FOG_COORDS(7)
			};


			fixed OrenNayarDiffuse(fixed3 light, fixed3 view, fixed3 norm, fixed roughness)
			{
				half VdotN = dot(view, norm);
				
				
				half LdotN = saturate(4 * dot(light, norm * float3(1, 0.5, 1))); // the function is modifed here
				// the original one is LdotN = saturate( dot ( light , norm ))
				
				half cos_theta_i = LdotN;
				half theta_r = acos(VdotN);
				half theta_i = acos(cos_theta_i);
				half cos_phi_diff = dot(normalize(view - norm * VdotN),
				normalize(light - norm * LdotN));
				half alpha = max(theta_i, theta_r) ;
				half beta = min(theta_i, theta_r) ;
				half sigma2 = roughness * roughness;
				half A = 1.0 - 0.5 * sigma2 / (sigma2 + 0.33);
				half B = 0.45 * sigma2 / (sigma2 + 0.09);
				
				return saturate(cos_theta_i) *
				(A + (B * saturate(cos_phi_diff) * sin(alpha) * tan(beta)));
			}
			float SpecularDistribution(float3 lightDir, float3 view, float3 normal, float3 normalDetail)
			{
				// using the blinn model
				// base shine come use the normal of the object
				// detail shine use the normal from the detail normal image
				float3 halfDirection = normalize(view + lightDir);

				float baseShine = pow(saturate(dot(halfDirection, normal)), 10 / _BaseRoughness);
				float shine = pow(saturate(dot(halfDirection, normalDetail)), 10 / _DetailRoughness)  ;

				return baseShine * shine;
			}
			
			float3 GetGlitterNoise(float2 uv)
			{
				return tex2D(_GlitterTex, _GlitterTex_ST.xy * uv.xy + _GlitterTex_ST.zw) ;
			}

			float GliterDistribution(float3 lightDir, float3 normal, float3 view, float2 uv, float3 pos)
			{


				
				float specBase = saturate(1 - dot(normal, view) * 1);
				float specPow = pow(specBase, 10 / _GlitterRange);



				// Get the glitter sparkle from the noise image
				float3 noise = GetGlitterNoise(uv);

				// A very random function to modify the glitter noise
				float p1 = GetGlitterNoise(uv + float2(0, view.x * 0.006)).r;
				float p2 = GetGlitterNoise(uv + float2(0, view.y * 0.004)).g;
				

				//float sum = (p1 + p2) * (p3 + p4);
				float sum = 4 * p1 * p2;

				float glitter = pow(sum, _Glitterness);
				glitter = max(0, glitter * _GlitterMutiplyer - 0.5) * 2 * (1 + sin(pos.x + _Time.y));
				float sparkle = glitter * specPow;

				return sparkle;
			}

			float SchlickFresnel(float i)
			{
				float x = clamp(1.0 - i, 0.0, 1.0);
				float x2 = x * x;
				return x2 * x2 * x;
			}
			float4 FresnelFunction(float3 SpecularColor, float3 light, float3 viewDirection)
			{
				float3 halfDirection = normalize(light + viewDirection);
				float power = SchlickFresnel(max(0, dot(light, halfDirection)));
				
				return float4(SpecularColor + (1 - SpecularColor) * power, 1);
			}
			float GGXGeometricShadowingFunction(float3 light, float3 view, float3 normal, float roughness)
			{
				
				float NdotL = max(0, dot(normal, light));
				float NdotV = max(0, dot(normal, view));
				float roughnessSqr = roughness * roughness;
				float NdotLSqr = NdotL * NdotL;
				float NdotVSqr = NdotV * NdotV;
				
				
				float SmithL = (2 * NdotL) / (NdotL + sqrt(roughnessSqr +
				(1 - roughnessSqr) * NdotLSqr));
				float SmithV = (2 * NdotV) / (NdotV + sqrt(roughnessSqr +
				(1 - roughnessSqr) * NdotVSqr));
				
				
				float Gs = (SmithL * SmithV);
				return Gs;
			}
			v2f vert(appdata_full v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
				o.uv = v.texcoord;
				o.uvLM_Ctrl = v.texcoord1;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);//(0,1,0)
				o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);//(1,0,0)
				o.worldBitangent = cross(o.worldTangent, o.worldNormal);
				o.worldView = WorldSpaceViewDir(v.vertex);
				TRANSFER_SHADOW(o);
				UNITY_TRANSFER_FOG(o, o.pos);
				return o;
			}
			
			fixed4 frag(v2f i): SV_Target
			{

				fixed4 splat_control = tex2D(_Control, i.uvLM_Ctrl);
				fixed4 mixedAlbedo = 0.0f;
				mixedAlbedo += splat_control.r * tex2D(_Splat0, i.uv * _Splat0_ST.xy + _Splat0_ST.zw);
				mixedAlbedo += splat_control.g * tex2D(_Splat1, i.uv * _Splat1_ST.xy + _Splat1_ST.zw);
				mixedAlbedo += splat_control.b * tex2D(_Splat2, i.uv * _Splat2_ST.xy + _Splat2_ST.zw);
				mixedAlbedo += splat_control.a * tex2D(_Splat3, i.uv * _Splat3_ST.xy + _Splat3_ST.zw);
				
				fixed4 mixedNormal = 0.0f;
				mixedNormal += splat_control.r * tex2D(_Normal0, i.uv * _Splat0_ST.xy + _Splat0_ST.zw);
				mixedNormal += splat_control.g * tex2D(_Normal1, i.uv * _Splat1_ST.xy + _Splat1_ST.zw);
				mixedNormal += splat_control.b * tex2D(_Normal2, i.uv * _Splat2_ST.xy + _Splat2_ST.zw);
				mixedNormal += splat_control.a * tex2D(_Normal3, i.uv * _Splat3_ST.xy + _Splat3_ST.zw);
				float3x3 TBN = float3x3(normalize(i.worldTangent), normalize(i.worldBitangent), normalize(i.worldNormal));
				float3x3  TBN_t = transpose(TBN);

				fixed3 detailNormal = normalize(UnpackNormal(tex2D(_DetailNRMTexture, i.uv * _DetailNRMTexture_ST.xy + _DetailNRMTexture_ST.zw)));
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldView = normalize(i.worldView);
				
				// Get the texel in the normal map
				fixed3 tangleNormal = UnpackNormal(mixedNormal);
				detailNormal.xy *= _DetailNormalScale;
				detailNormal.z = sqrt(1.0 - saturate(dot(detailNormal.xy, detailNormal.xy)));
				detailNormal = mul(TBN_t, detailNormal);
				tangleNormal.xy *= _NormalScale * (3*i.worldNormal.y-2);//越陡峭的地方 沙子的静态纹路就越浅
				tangleNormal.z = sqrt(1.0 - saturate(dot(tangleNormal.xy, tangleNormal.xy)));
				fixed3 worldNormal = mul(TBN_t, tangleNormal);
				
				//Get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				// Get the normal in world space
				
				
				// Compute diffuse term
				fixed3 nearLightColor = _LightColor0.rgb - fixed3(0.1, 0.5, 1.0) * clamp(1.0 - 2*WorldSpaceLightDir(i.pos).y,0.3,1.0);
				fixed3 diffuse = 0, specular = 0;

				//diffuse = nearLightColor * mixedAlbedo *OrenNayarDiffuse(tangentLightDir,tangentViewDir,tangentNormal,_Roughness);// max(0.0, dot(tangentNormal, tangentLightDir));
				diffuse = nearLightColor * mixedAlbedo * max(0.0, dot(worldNormal, worldLightDir));
				specular = _OceanSpecularColor * mixedAlbedo * SpecularDistribution(worldLightDir, worldView, worldNormal, detailNormal)
				* GGXGeometricShadowingFunction(worldLightDir, worldView, detailNormal, _Roughness)
				* FresnelFunction(nearLightColor, worldLightDir, worldView)
				/ abs(4 * max(0.1, dot(detailNormal, worldLightDir)) * max(0.1, dot(detailNormal, worldView)));;
				
				
				fixed shadow = SHADOW_ATTENUATION(i);
				
				fixed3 indirectDiffuse = 0.0f;
				#ifndef LIGHTMAP_OFF
					indirectDiffuse = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.uvLM_Ctrl));
				#endif
				
				fixed shadowFromLM = UnitySampleBakedOcclusion(i.uvLM_Ctrl, i.worldPos);
				float zDist = dot(_WorldSpaceCameraPos - i.worldPos, UNITY_MATRIX_V[2].xyz);
				float fadeDist = UnityComputeShadowFadeDistance(i.worldPos, zDist);
				shadow = UnityMixRealtimeAndBakedShadows(shadow, shadowFromLM, UnityComputeShadowFade(fadeDist));
				fixed3 gliterRes = _GlitterColor.xyz * GliterDistribution(worldLightDir, detailNormal, worldView, i.uv, i.pos);
				fixed3 color = ambient + (specular + diffuse + gliterRes) * shadow + indirectDiffuse * _IndirectScale;
				//color *=pow(i.pos.z,0.1);
				UNITY_APPLY_FOG(i.fogCoord, color);
				return fixed4(color, 1.0);
				//return fixed4( frac(i.uv * _Splat0_ST.xy + _Splat0_ST.zw) ,0, 1.0);
				return fixed4(i.worldNormal,1);
			}
			
			ENDCG
			
		}
	}

	Dependency "AddPassShader" = "Hidden/TerrainEngine/Splatmap/Standard-AddPass"
	Dependency "BaseMapShader" = "Hidden/TerrainEngine/Splatmap/Standard-Base"
	Fallback "Nature/Terrain/Diffuse"
}
