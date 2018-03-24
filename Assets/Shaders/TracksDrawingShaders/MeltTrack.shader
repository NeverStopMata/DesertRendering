Shader "Mata/visual_effect/SplatRecoverShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" { }
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100
		
		Pass
		{
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "desert_common.cginc"
			
			struct appdata
			{
				float4 vertex: POSITION;
				float2 uv: TEXCOORD0;
			};
			
			struct v2f
			{
				float2 uv: TEXCOORD0;
				float4 vertex: SV_POSITION;
			};
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag(v2f i): SV_Target
			{
				// sample the texture
				float4 lastHeight = tex2D(_MainTex, i.uv);
				lastHeight.y -= 0.2;
				if (lastHeight.y > 0)
				{
					return lastHeight;
				}

				float3 tangleNormal = GetNormalFromHeightmap(_MainTex, i.uv, 0.003,0.5);
				// if(tangleNormal.y>cos(radians(30)))
				// {
				// 	return lastHeight;
				// }
				
				float2 probeVec = -normalize(tangleNormal.xy);
				float2 orthgnProbeVec = float2(0.86,0.5);
				float distrubuteDist = 0.0005;
				
				lastHeight.y = 0;

				float highDelta =  tex2D(_MainTex, i.uv +  probeVec * distrubuteDist).x - lastHeight.x;
				float lowDelta =  lastHeight.x - tex2D(_MainTex, i.uv -  probeVec * distrubuteDist).x;
				lastHeight.x  = lastHeight.x + 0.25*highDelta -0.3*lowDelta;
				lastHeight.x += 0.05*clamp(0.5 - lastHeight.x,0,0.5);
				//lastHeight.x = 0.2 * tex2D(_MainTex, i.uv +  orthgnProbeVec * distrubuteDist * 0.1).x + lastHeight.x * 0.6 + 0.2 * tex2D(_MainTex, i.uv -  orthgnProbeVec * distrubuteDist * 0.1).x;
				// if(lastHeight.x > 0.5)
				// {
				// 	lastHeight.x -= 0.001;
				// 	if(lastHeight.x < 0.5)
				// 		lastHeight.x = 0.5;
				// 	return lastHeight;
				// }
				// else if(lastHeight.x < 0.5)
				// {
				// 	lastHeight.x += 0.001;
				// 	if(lastHeight.x > 0.5)
				// 		lastHeight.x = 0.5;
				// 	return lastHeight;
				// }
				// else
				// {
				// 	return lastHeight;
				// }
				//return fixed4(tangleNormal,1);
				return lastHeight;
			}
			ENDCG
			
		}
	}
}
