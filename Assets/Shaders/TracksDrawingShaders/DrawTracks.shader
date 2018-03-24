Shader "Mata/visual_effect/DrawtracksShader"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" { }
		_StampTex ("Texture", 2D) = "white" { }
		// _Coordinate ("Conrdinate", Vector) = (0, 0, 0, 0)
		// _CoordsNum ("Coords Num", float) = 0
		// _LastCoordinate ("LastCoordinate", Vector) = (0, 0, 0, 0)
		_Color ("Draw Color", Color) = (1, 0, 0, 0)
		_TrackSize ("Track Size", Range(0, 1)) = 0.5
		_TrackStrength ("Track Strength", Range(0, 0.05)) = 0.03
		_HeightOffset ("Stamp Height OFfset", Range(0, 1)) = 0.5
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
			#pragma StandardSpecular fullforwardshadows addshadow  nolightmap
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
				float2 uv1: TEXCOORD0;
				float4 vertex: SV_POSITION;
			};
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _StampTex;
			float4 _StampTex_ST;
			
			uniform float4 _Coordinates[3];  // 数组变量
			uniform float _CoordsNum;  // 数组长度变量
			fixed4  _Color;
			float _TrackSize;
			float _TrackStrength;
			
			
			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag(v2f i): SV_Target
			{
				//sample the texture
				float4 _Coordinate;
				float4 _LastCoordinate;
				_Coordinate = _Coordinates[int(_CoordsNum-1)];
				_LastCoordinate = _Coordinates[int(clamp(_CoordsNum-2,0,2))];

				float origHeight = tex2D(_MainTex, i.uv).r;
				float2 v1 = normalize(i.uv - _Coordinate.xy);
				float2 v2 = normalize(i.uv - _LastCoordinate.xy);
				float2 v0 = normalize(_Coordinate.xy - _LastCoordinate.xy);
				float dotVal1 = dot(v0, v1);
				float dotVal2 = dot(v0, v2);
				float dist = 100;
				
				
				if (_CoordsNum == 1)
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
				
				
				
				
				dist = pow(dist, 2);
				float waveLength = 3.1415926 * _TrackSize / 1000;
				float frequence = 2000 / _TrackSize;
				if (dist > waveLength)//距离较远 没影响到
				{
					return _Color * origHeight + fixed4(0, tex2D(_MainTex, i.uv).g, 0, 0);
				}
				
				
				//计算沙子最终的高度信息
				
				float increaseHeight = -_TrackStrength * cos(frequence * dist);
				fixed4 drwaCol;
				
				//下压区域
				if (dist < waveLength / 4)
				{
					drwaCol = _Color * (increaseHeight * 5 + 0.5);
				}
				
				
				//因为再分配产生的上升
				else if (dist >= waveLength / 4 && dist <= waveLength)
				{
					if(dist >= waveLength / 2)
						increaseHeight += 0.5 * _TrackStrength * cos(frequence * dist) + 0.5 * _TrackStrength;
					if(dotVal1 >= 0.5 && _LastCoordinate.w != 1)//前端
					{
						
						increaseHeight += _TrackStrength * (cos(2 * 3.1415926 * dotVal1) + 1) * (1 - cos(4 * frequence * dist / 3 - 2 * 3.1415926 / 3));
					}
					//float distrubuteRate = GetDepressRatio(v1,_TrackInf.x);
					//if(increaseHeight+0.5 > origHeight)
					//drwaCol = _Color * (increaseHeight *saturate(1.0-0*pow(origHeight-0.5,2))  + origHeight);
					drwaCol = _Color * (increaseHeight + origHeight);
					//drwaCol = _Color * (increaseHeight  + 0.5);
				}
				
				drwaCol.y = 1;
				
				
				return saturate(drwaCol);
			}
			ENDCG
			
		}
	}
}


