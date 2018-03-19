// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Mata/visual_effect/SandTracks"
{
	// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
	// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
	
	Properties
	{
		
		
		_Tess ("Tessellation", Range(1, 32)) = 4
		_Displacement ("Displacement", Range(0.0, 1.0)) = 0.25
		_SnowColor ("Snow Color", Color) = (1, 1, 1, 1)
		_SnowTex ("Snow (RGB)", 2D) = "white" { }
		_GroundColor ("Ground Color", Color) = (1, 1, 1, 1)
		_GroundTex ("Ground (RGB)", 2D) = "white" { }
		_Splat ("SplatMap", 2D) = "black" { }
		
		_MinDist ("Tessellation MinDist", Range(1, 5)) = 3
		_MaxDist ("Tessellation MaxDist", Range(5, 30)) = 15
		
		_Delta ("delta for computing normal for heightmap", Range(0.0001, 0.01)) = 0.001
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
			#include "Tessellation.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			
			float _Tess;
			sampler2D _Splat;
			float4 _Splat_ST;
			
			sampler2D _GroundTex;
			fixed4 _GroundColor;
			
			sampler2D _SnowTex;
			fixed4 _SnowColor;
			
			float _MinDist;
			float _MaxDist;// ("Tessellation MaxDist", Range(5, 30)) = 1.0;
			float _Displacement;
			float _Delta;
			struct a2v
			{
				float4 vertex: POSITION;
				fixed3 normal: NORMAL;
				fixed4 texcoord: TEXCOORD0;
				fixed4 tangent: TANGENT;
			};
			
			
			struct v2f
			{
				float4 pos: POSITION;
				fixed2 uv: TEXCOORD0;
				fixed3 lightDir: TEXCOORD1;
				float3 worldTangent: TEXCOORD2;     // tangent direction in world
				float3 worldBitangent: TEXCOORD3;   // bitangent direction in world
				float3 worldNormal: NORMAL;
				float3 worldPos: TEXCOORD4;
				LIGHTING_COORDS(5, 6)
				//SHADOW_COORDS(5)
			};
			
			
			
			float3 GetNormalFromHeightmap(sampler2D Heightmap, float2 uv, float delta)
			{
				float s0 = tex2D(Heightmap, uv + float2(-delta, 0)).r;
				float s1 = tex2D(Heightmap, uv + float2(delta, 0)).r;
				float s2 = tex2D(Heightmap, uv + float2(0, -delta)).r;
				float s3 = tex2D(Heightmap, uv + float2(0, delta)).r;
				float3 U = float3(2 * delta, 0, (s1 - s0)*_Displacement);
				float3 V = float3(0, 2 * delta, (s3 - s2)*_Displacement);
				float3 normal = normalize(cross(U, V));
				return normal;
			}
			
			v2f vert(a2v v)
			{
				v2f o;
				
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.texcoord, _Splat);
				o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
				//为切线空间创建一个旋转矩阵
				TANGENT_SPACE_ROTATION;
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex));
				
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				o.worldBitangent = cross(o.worldTangent, o.worldNormal);// * v.tangent.w;
				//TRANSFER_SHADOW(o);
				// pass lighting information to pixel shader
				TRANSFER_VERTEX_TO_FRAGMENT(o);
				return o;
			}
			#ifdef UNITY_CAN_COMPILE_TESSELLATION
				struct TessVertex
				{
					float4 vertex: INTERNALTESSPOS;
					fixed4 texcoord: TEXCOORD0;
					float3 normal: NORMAL;
					float4 tangent: TANGENT;
				};
				struct OutputPatchConstant
				{
					float edge[3]: SV_TessFactor;
					float inside: SV_InsideTessFactor;
					float3 vTangent[4]: TANGENT;
					float2 vUV[4]: TEXCOORD;
					float3 vTanUCorner[4]: TANUCORNER;
					float3 vTanVCorner[4]: TANVCORNER;
					float4 vCWts: TANWEIGHTS;
				};
				TessVertex tessvert(a2v v)
				{
					TessVertex o;
					o.vertex = v.vertex;
					o.normal = v.normal;
					o.tangent = v.tangent;
					o.texcoord = v.texcoord;
					return o;
				}
				float Tessellation(TessVertex v)
				{
					return _Tess;
				}
				float4 Tessellation(TessVertex v, TessVertex v1, TessVertex v2)
				{
					return UnityDistanceBasedTess(v.vertex, v1.vertex, v2.vertex, _MinDist, _MaxDist, _Tess);
				}
				OutputPatchConstant hullconst(InputPatch < TessVertex, 3 > v)
				{
					OutputPatchConstant o = (OutputPatchConstant)0;
					float4 ts = Tessellation(v[0], v[1], v[2]);
					o.edge[0] = ts.x;
					o.edge[1] = ts.y;
					o.edge[2] = ts.z;
					o.inside = ts.w;
					return o;
				}
				[domain("tri")]
				[partitioning("fractional_odd")]
				[outputtopology("triangle_cw")]
				[patchconstantfunc("hullconst")]
				[outputcontrolpoints(3)]
				TessVertex hull(InputPatch < TessVertex, 3 > v, uint id: SV_OutputControlPointID)
				{
					
					return v[id];
				}
				[domain("tri")]
				v2f domain(OutputPatchConstant tessFactors, const OutputPatch < TessVertex, 3 > vi, float3 bary: SV_DomainLocation)
				{
					a2v v = (a2v)0;
					v.vertex = vi[0].vertex * bary.x + vi[1].vertex * bary.y + vi[2].vertex * bary.z;
					v.normal = vi[0].normal * bary.x + vi[1].normal * bary.y + vi[2].normal * bary.z;
					v.tangent = vi[0].tangent * bary.x + vi[1].tangent * bary.y + vi[2].tangent * bary.z;
					v.texcoord = vi[0].texcoord * bary.x + vi[1].texcoord * bary.y + vi[2].texcoord * bary.z;
					float d = (tex2Dlod(_Splat, v.texcoord).r-0.5) * _Displacement;//置换纹理采样
					v.vertex.xyz += v.normal * d;//置换顶点
					v2f o = vert(v);
					return o;
				}
			#endif
			fixed4 frag(v2f i): COLOR
			{
				
				fixed4 o;
				half amount = tex2Dlod(_Splat, float4(i.uv, 0, 0)).r;
				fixed4 c = lerp(tex2D(_SnowTex, i.uv) * _SnowColor, tex2D(_GroundTex, i.uv) * _GroundColor, amount);
				//	fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
				o.rgb = c.rgb;
				// Metallic and smoothness come from slider variables
				
				o.a = 1.0;
				fixed3 tangleNormal = GetNormalFromHeightmap(_Splat, i.uv, _Delta);
				float3x3 TBN = float3x3(normalize(i.worldTangent), normalize(i.worldBitangent), normalize(i.worldNormal));
				float3x3  TBN_t = transpose(TBN);
				// fixed4 texColor = tex2D(_, i.uv);
				// fixed3 norm = UnpackNormal(tex2D(_Bump, i.uv));
				float3 worldPos = i.worldPos;
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				// //norm.y*=-1;//这个是作者实验的法线纹理是反向的，在这修正一下，正常的法线纹理需要注释掉
				fixed3 worldNormal = mul(TBN_t, tangleNormal);
				
				fixed  atten = LIGHT_ATTENUATION(i);
				
			    fixed3 ambi = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				fixed3 diff = _LightColor0.rgb * saturate(dot(normalize(worldNormal), normalize(lightDir)));
				
				// fixed3 lightRefl = reflect(-lightDir, worldNormal);
				// fixed3 spec = _LightColor0.rgb * pow(saturate(dot(normalize(lightRefl), normalize(worldViewDir))), _Specular) * _Gloss;
				
				// fixed3 worldView = fixed3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				// fixed3 worldRefl = reflect(-worldViewDir, worldNormal);
				
				// fixed4 fragColor;
				// fragColor.rgb = float3((ambi + (diff + spec) * atten) * texColor);
				// fragColor.a = 1.0f;
				
				//return o;
				return fixed4(ambi + diff * atten, 1);
			}
			
			ENDCG
			
		}
	}
	FallBack "Diffuse"
}