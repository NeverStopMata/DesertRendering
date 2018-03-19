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
			// float GetDepressRatio(float2 probeVec, float _TrackInf_freq)
			// {
				
				// 	float quartPeriod = pow(3.1415926 / (2 * _TrackInf_freq), 0.5);
				// 	float quartPeriod_2 = 3.1415926 / (2 * _TrackInf_freq);
				// 	float4 innerTargetHeights = float4(-0.1 * cos(_TrackInf_freq * pow(0, 2) * quartPeriod_2 / 64),
				// 	- 0.1 * cos(_TrackInf_freq * pow(1, 2) * quartPeriod_2 / 64),
				// 	- 0.1 * cos(_TrackInf_freq * pow(2, 2) * quartPeriod_2 / 64),
				// 	- 0.1 * cos(_TrackInf_freq * pow(3, 2) * quartPeriod_2 / 64));
				// 	float4 outerTargetHeights = float4(-0.1 * cos(_TrackInf_freq * pow(4, 2) * quartPeriod_2 / 64),
				// 	- 0.1 * cos(_TrackInf_freq * pow(5, 2) * quartPeriod_2 / 64),
				// 	- 0.1 * cos(_TrackInf_freq * pow(6, 2) * quartPeriod_2 / 64),
				// 	- 0.1 * cos(_TrackInf_freq * pow(7, 2) * quartPeriod_2 / 64));
				
				// 	float4 innerSamples = float4(tex2D(_MainTex, _Coordinate + probeVec * 0 * quartPeriod / 8).r - 0.5,
				// 	tex2D(_MainTex, _Coordinate + probeVec * 1 * quartPeriod / 8).r - 0.5,
				// 	tex2D(_MainTex, _Coordinate + probeVec * 2 * quartPeriod / 8).r - 0.5,
				// 	tex2D(_MainTex, _Coordinate + probeVec * 3 * quartPeriod / 8).r - 0.5);
				// 	float4 outerSamples = float4(tex2D(_MainTex, _Coordinate + probeVec * 4 * quartPeriod / 8).r - 0.5,
				// 	tex2D(_MainTex, _Coordinate + probeVec * 5 * quartPeriod / 8).r - 0.5,
				// 	tex2D(_MainTex, _Coordinate + probeVec * 6 * quartPeriod / 8).r - 0.5,
				// 	tex2D(_MainTex, _Coordinate + probeVec * 7 * quartPeriod / 8).r - 0.5);
				
				// 	float ObjectVolume = dot(float4(0, 0, 0, 0) - innerTargetHeights, float4(1, 3, 5, 7)) + dot(float4(0, 0, 0, 0) - outerTargetHeights, float4(9, 11, 13, 15));
				// 	float CollisonVolume = dot(innerSamples  - innerTargetHeights, float4(1, 3, 5, 7)) + dot(outerSamples  - outerTargetHeights, float4(9, 11, 13, 15));
				// 	return CollisonVolume / ObjectVolume;
				// 	//return 0.5;
				// }
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
					else if(dotVal1 >= 0)
					{
						dist = distance(i.uv, _Coordinate.xy);// * (1 - 0.3 * dotVal1);
					}
					else if (dotVal1 < 0 && dotVal2 >= 0)
					{
						float2 vecCurrentCoord2Pos = i.uv - _Coordinate.xy;
						float2 Pedal = _Coordinate.xy + v0 * dot(v0, vecCurrentCoord2Pos);
						dist = distance(Pedal, i.uv);
					}
					//float dist = distance(i.uv, _Coordinate.xy);
					
					
					
					float _TrackSize = _TrackInf.x;
					dist = pow(dist, 2);
					if (dist > 3.1415926 * 2 / _TrackSize)//距离较远 没影响到
					{
						return _Color * origHeight + fixed4(0,tex2D(_MainTex, i.uv).g,0,0);
					}
					
					
					//计算沙子最终的高度信息
					float upScale = 0.05;
					float increaseHeight = -upScale * cos(_TrackSize * dist);
					fixed4 drwaCol;
					
					//下压区域
					if ((dist < 3.1415926 / (_TrackSize * 2) && increaseHeight + 0.5 <= origHeight) || dotVal2 <= 0)
					{
						drwaCol = _Color * (increaseHeight + 0.5);
					}

					// if (dist < 3.1415926 / (_TrackSize * 2) || dotVal2 <= 0)
					// {
					// 	drwaCol = _Color * (increaseHeight + origHeight);
					// }
					//因为再分配产生的上升
					else if (dist >= 3.1415926 / (_TrackSize * 2) && dist <= 3.1415926 * 2 / _TrackSize)
					{
						if(dist >= 3.1415926 / (_TrackSize))
							increaseHeight += 0.5 * upScale * cos(_TrackSize * dist) + 0.5 * upScale;
						if(dotVal1 >= 0)//前端
						{
							//increaseHeight *= 1 + (dotVal1 + 0.5) * 2;
							increaseHeight += upScale * (1 - cos(3.1415926 * dotVal1)) * (1 - cos(4 * _TrackSize * dist / 3 - 2 * 3.1415926 / 3));
						}
						//float distrubuteRate = GetDepressRatio(v1,_TrackInf.x);
						//if(increaseHeight+0.5 > origHeight)
						//drwaCol = _Color * (increaseHeight + origHeight);
						//drwaCol = _Color * (increaseHeight * (increaseHeight + 0.5 - origHeight) + origHeight);
						drwaCol = _Color * (increaseHeight  + 0.5);
					}
					
					drwaCol.y = 1;
					return saturate(drwaCol);
				}
				ENDCG
				
			}
		}
	}
	
	
	//在沙痕顶端
	// if (dotVal1 > 0)
	// {
		// 	//下压区域
		// 	if (dist < 3.1415926 / (_TrackSize * 2) && increaseHeight + 0.5 < origHeight)
		// 	{
			// 		drwaCol = _Color * (increaseHeight + 0.5);
			// 	}
			// 	//因再分配产生的上升
			// 	else if (dist >= 3.1415926 / (_TrackSize * 2) && dist <= 3.1415926 * 2 / _TrackSize)
			// 	{
				// 		increaseHeight += 0.05 * cos(_TrackSize * dist) + 0.05;
				// 		increaseHeight *= 1 + (dotVal1 + 0.5) * 2;
				// 		drwaCol = _Color * (0 + origHeight);
				// 	}
				// }
				
				// //在沙痕的两侧
				// else if (dotVal2 > 0)
				// {
					// 	//下压区域
					// 	if (dist < 3.1415926 / (_TrackSize * 2) && increaseHeight + 0.5 < origHeight)
					// 	{
						// 		drwaCol = _Color * (increaseHeight + 0.5);
						// 	}
						// 	//因为再分配产生的上升
						// 	else if (dist >= 3.1415926 / (_TrackSize * 2) && dist <= 3.1415926 * 2 / _TrackSize)
						// 	{
							// 		increaseHeight += 0.05 * cos(_TrackSize * dist) + 0.05;
							// 		drwaCol = _Color * (0 + origHeight);
							// 	}
							// }
							
							
							
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
									// drwaCol = _Color * (0.5);