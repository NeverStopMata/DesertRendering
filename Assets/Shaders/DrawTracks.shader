Shader "Mata/visual_effect/DrawtracksShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" { }
		_Coordinate ("Conrdinate", Vector) = (0, 0, 0, 0)
		_LastCoordinate ("LastCoordinate", Vector) = (0, 0, 0, 0)
		_Color ("Draw Color", Color) = (1, 0, 0, 0)
		_TrackInf ("Track Inf", Vector) = (1, 0, 0, 0)
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
			fixed4 _Coordinate, _LastCoordinate, _Color;
			float4 _TrackInf;
			float GetDepressRatio(sampler2D originHeightMap,float2 _Coordinate,float2 probeVec,float4 _TrackInf)
			{
				//float4 innerSamples = float4( -0.1 * cos(_TrackSize * 0));
				//float4 outterSamples = float4()
				return 0;
			}
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
				float origHeight = tex2D(_MainTex, i.uv).r;
				float2 v1 = normalize(i.uv - _Coordinate.xy);
				float2 v2 = normalize(i.uv - _LastCoordinate.xy);
				float2 v0 = normalize(_Coordinate.xy - _LastCoordinate.xy);
				float dotVal1 = dot(v0, v1);
				float dotVal2 = dot(v0, v2);
				float dist = 100;
				if (_LastCoordinate.w == 1)
				{
					dist = distance(i.uv, _Coordinate.xy);
				}
				else if(dotVal1 > 0)
				{
					dist = distance(i.uv, _Coordinate.xy) * (1 - 0.3 * dotVal1);
				}
				else if(dotVal1 <= 0 && dotVal2 > 0)
				{
					float2 vecCurrentCoord2Pos = i.uv - _Coordinate.xy;
					float2 Pedal = _Coordinate.xy + v0 * dot(v0, vecCurrentCoord2Pos);
					dist = distance(Pedal, i.uv);
				}
				//float dist = distance(i.uv, _Coordinate.xy);
				
				
				
				float _TrackSize = _TrackInf.x;
				dist = pow(2 * dist, 2);
				if (dist > 3.1415926 * 2 / _TrackSize)//距离较远 没影响到
				return _Color * origHeight;
				
				//计算沙子最终的高度信息
				float increaseHeight = -0.1 * cos(_TrackSize * dist);
				fixed4 drwaCol;

				//在沙痕顶端
				if (dotVal1 > 0)
				{
					//下压区域
					if (dist < 3.1415926 / (_TrackSize * 2) && increaseHeight + 0.5 < origHeight)
					{
						drwaCol = _Color * (increaseHeight + 0.5);
					}
					//因再分配产生的上升
					else if (dist >= 3.1415926 / (_TrackSize * 2) && dist <= 3.1415926 * 2 / _TrackSize)
					{
						increaseHeight += 0.05 * cos(_TrackSize * dist) + 0.05;
						increaseHeight *= 1 + (dotVal1 + 0.5) * 2;
						drwaCol = _Color * (0 + origHeight);
					}
				}

				//在沙痕的两侧
				else if(dotVal2 > 0)
				{
					if (dist < 3.1415926 / (_TrackSize * 2) && increaseHeight + 0.5< origHeight)//下压区域
					{
						drwaCol = _Color * (increaseHeight + 0.5);
					}
					//因为再分配产生的上升
					else if (dist >= 3.1415926 / (_TrackSize * 2) && dist <= 3.1415926 * 2 / _TrackSize)
					{
						increaseHeight += 0.05 * cos(_TrackSize * dist) + 0.05;
						drwaCol = _Color * (0 + origHeight);
					}
				}
				
				
				
				//saturate(pow(20*(distance(i.uv,_Coordinate.xy)),2))*0.5;
				// fixed4 drwaCol = _Color * origHeight;
				// if (dist < 3.1415926 / (_TrackSize * 2) && origHeight > targetHeight)
				// {
					// 	drwaCol = _Color * (targetHeight);
					// }
					
					// else if(dotVal1 > 0 && (dist < 2 * 3.1415926 / _TrackSize) && (dist >= 3.1415926 * 0.5 / _TrackSize))
					// {
						// 	targetHeight = targetHeight + (targetHeight - 0.5) * (dotVal1 + 0.5) * 2;
						// 	drwaCol = _Color * (targetHeight);
						// }
						// //else if(targetHeight > 0.5)
						// 	//drwaCol = _Color * (col + _intense * (targetHeight - 0.5));
						// 	drwaCol = _Color * (0.5);
						return saturate(drwaCol);
					}
					ENDCG
					
				}
			}
		}
