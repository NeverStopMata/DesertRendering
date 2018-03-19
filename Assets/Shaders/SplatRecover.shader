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
				float4 lastHeight = tex2D(_MainTex,i.uv);
				lastHeight.y -= 0.01;
				if(lastHeight.y <=0)
				{
					lastHeight.y = 0;
					lastHeight.x = 0.5 + (lastHeight.x - 0.5) * 0.95;
				}
				
				return lastHeight;
			}
			ENDCG
			
		}
	}
}
