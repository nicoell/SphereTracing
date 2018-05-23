#ifndef STRUCTS_INCLUDED
#define STRUCTS_INCLUDED

struct SurfaceData
{
    float3 Position;
    float MaterialId;
    float3 Normal;
    float Alpha;
};

struct AmbientOcclusion
{
    float3 BentNormal;
    float SpecularOcclusion;
};

struct StUnion
{
    SurfaceData Surface;
	SurfaceData Represent;
	AmbientOcclusion SurfaceAo;
	AmbientOcclusion RepresentAo;
	float SurfaceDepth;
	float RepresentDepth;
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
	float4 DiffuseColor;
	float4 SpecularColor;
	float Shininess;
	float ReflectiveF;
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

#endif // STRUCTS_INCLUDED