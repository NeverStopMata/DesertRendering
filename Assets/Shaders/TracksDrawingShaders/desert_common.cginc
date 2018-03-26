#ifndef DESSERT_COMMON
	
	#define DESSERT_COMMON
	#include "Lighting.cginc"
	#include "AutoLight.cginc"
	#include "Tessellation.cginc"
	sampler2D _Splat;
	float4 _Splat_ST;
	
	sampler2D _GroundTex;
	fixed4 _GroundColor;
	
	sampler2D _SnowTex;
	fixed4 _SnowColor;
	
	//float _MinDist;
	//float _MaxDist;// ("Tessellation MaxDist", Range(5, 30)) = 1.0;
	float _Displacement;
	float _Delta;
	float _Tess;
	float _MinDist;
	float _MaxDist;// ("Tessellation MaxDist", Range(5, 30)) = 1.0;
	float4 _ActorWorldPos;
	float _SampleAreaSize;
	float _HeightOffset;
	float3 GetNormalFromHeightmap(sampler2D Heightmap, float2 uv, float delta, float displacement)
	{
		float s0 = tex2D(Heightmap, uv + float2(-delta, 0)).r;
		float s1 = tex2D(Heightmap, uv + float2(delta, 0)).r;
		float s2 = tex2D(Heightmap, uv + float2(0, -delta)).r;
		float s3 = tex2D(Heightmap, uv + float2(0, delta)).r;
		float3 U = float3(-2 * delta, 0, (s1 - s0) * displacement);
		float3 V = float3(0, -2 * delta, (s3 - s2) * displacement);
		float3 normal = normalize(cross(U, V));
		return normal;
	}
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
	
	// float3 calcNormal(float2 texcoord)
	// {
		// 	const float3 off = float3(-0.01f, 0, 0.01f); // texture resolution to sample exact texels
		// 	const float2 size = float2(0.01, 0.0); // size of a single texel in relation to world units
		
		// 	float s01 = tex2Dlod(_Splat, float4(texcoord.xy - off.xy, 0, 0)).x * _Displacement;
		// 	float s21 = tex2Dlod(_Splat, float4(texcoord.xy - off.zy, 0, 0)).x * _Displacement;
		// 	float s10 = tex2Dlod(_Splat, float4(texcoord.xy - off.yx, 0, 0)).x * _Displacement;
		// 	float s12 = tex2Dlod(_Splat, float4(texcoord.xy - off.yz, 0, 0)).x * _Displacement;
		
		// 	float3 va = normalize(float3(size.xy, s21 - s01));
		// 	float3 vb = normalize(float3(size.yx, s12 - s10));
		
		// 	//return float3(s01, s12, 0);
		// 	return normalize(cross(va, vb));
		// }
		
		
		
		
		
		v2f vert(a2v v)
		{
			v2f o;
			
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = v.texcoord;
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
				//tmpUV += fixed2(0.5,0.5);
				float2 splatUV = float2(0.5, 0.5) + (mul(unity_ObjectToWorld, v.vertex).xz - _ActorWorldPos.xy) / _SampleAreaSize;
				float d = (tex2Dlod(_Splat, fixed4(splatUV, 0, 0)).r - 0.5) * _Displacement;//置换纹理采样
				v.vertex.xyz += v.normal * (d+_HeightOffset);//置换顶点
				v.normal = cross(normalize(vi[1].vertex - vi[0].vertex), normalize(vi[2].vertex - vi[0].vertex));
				v2f o = vert(v);
				return o;
			}
		#endif
	#endif //
	
