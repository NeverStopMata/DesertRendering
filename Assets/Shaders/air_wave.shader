Shader "mata/visual_effect/air_wave"
{
	Properties
	{
		_Color ("Main Color", Color) = (0, 0.15, 0.115, 1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_WaveMap ("Wave Map", 2D) = "bump" {}
		_Cubemap ("Environment Cubemap", Cube) = "_Skybox" {}
		_WaveXSpeed ("Wave Horizontal Speed", Range(-0.5, 0.5)) = 0.1
		_WaveYSpeed ("Wave Vertical Speed", Range(-0.5, 0.5)) = 0.1
		_Distortion ("Distortion", Range(0, 100)) = 10
		_HotWaveScale ("HotWaveScale", Range(0, 10)) = 5
	}
	SubShader
	{
		Tags { "Queue" = "Transparent" "RenderType" = "Opaque" }
		GrabPass
		{
			"_RefractionTex"
		}
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			
			#pragma multi_compile_fwdbase
			#pragma vertex vert
			#pragma fragment frag
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _WaveMap;
			float4 _WaveMap_ST;
			samplerCUBE _Cubemap;
			fixed _WaveXSpeed;
			fixed _WaveYSpeed;
			float _Distortion;	
			float _HotWaveScale;
			sampler2D _RefractionTex;
			float4 _RefractionTex_TexelSize;
			struct appdata
			{
				float4 vertex: POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT; 
				float2 uv: TEXCOORD0;
			};
			
			struct v2f
			{
				float4 pos: SV_POSITION;
				float4 scrPos : TEXCOORD0;
				float4 uv: TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;  
				float4 TtoW1 : TEXCOORD3;  
				float4 TtoW2 : TEXCOORD4; 
			};
			

			
			v2f vert(appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.scrPos =  ComputeGrabScreenPos(o.pos);
				o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.uv, _WaveMap);

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);  
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);  
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; 
				
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);  

				return o;
			}
			
			fixed4 frag(v2f i): SV_Target
			{

				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				float2 speed = _Time.y * float2(_WaveXSpeed, _WaveYSpeed);


				// Get the normal in tangent space
				fixed3 bump1 = UnpackNormal(tex2D(_WaveMap, i.uv.zw + speed)).rgb;
				fixed3 bump2 = UnpackNormal(tex2D(_WaveMap, i.uv.zw - speed)).rgb;
				fixed3 bump = normalize(bump1 + bump2);
				

				// Compute the offset in tangent space
				float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
				fixed3 backCol =  tex2D( _RefractionTex,i.scrPos.xy/i.scrPos.w).rgb;
				i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
				fixed3 refrCol = tex2D( _RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;

				// Convert the normal to world space
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				// fixed4 texColor = tex2D(_MainTex, i.uv.xy + speed);
				// fixed3 reflDir = reflect(-viewDir, bump);
				// fixed3 reflCol = fixed3(1,0,0);
				
				fixed fresnel = pow(1 - saturate(dot(viewDir, bump)), 4);
				float refrColAlph = pow(1-abs(viewDir.y),_HotWaveScale);
				fixed3 finalColor = refrCol * refrColAlph + backCol * (1-refrColAlph);
				return fixed4(finalColor,1.0);
			}
			ENDCG
			
		}
	}
}
