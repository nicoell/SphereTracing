#ifndef STRUCTS_INCLUDED
#define STRUCTS_INCLUDED

struct SphereTracingData
{
    float3 Position;
    float MaterialId;
    float3 RayDirection;
    float TraceDistance;
    float3 Normal;
    float Alpha;
};

struct AmbientOcclusion
{
    float3 BentNormal;
    float SpecularOcclusion;
};


struct Ray
{
    float2 uv;
	float3 Origin;
	float3 Direction;
};

struct StMaterial
{
	int MaterialType;
	float4 BaseColor;
	float4 EmissiveColor;
	float Metallic;
	float PerceptualRoughness;
};

struct Hit
{
	float3 Position;
	float TraceDistance;
	float DistanceToWorld;
	float Alpha;
	int MaterialId;
};

struct StLight
{
	int LightType;
	float4 LightData;
	float4 LightData2;
};

struct StMatrix
{
	float4x4 Matrix;
};

#endif // STRUCTS_INCLUDED