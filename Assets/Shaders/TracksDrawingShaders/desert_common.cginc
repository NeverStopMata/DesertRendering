#ifndef DESSERT_COMMON
	#define DESSERT_COMMON
	float3 GetNormalFromHeightmap(sampler2D Heightmap, float2 uv, float delta,float displacement)
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
	
#endif //
