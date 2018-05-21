#ifndef STRUCTDEFINITIONS_INCLUDED
#define STRUCTDEFINITIONS_INCLUDED

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
	float3 Normal;
	float TraceDistance;
	float DistanceToWorld;
	int MaterialId;
	StMaterial Material;
};

struct StLight
{
	int LightType;
	float4 LightData;
	float4 LightData2;
};



#endif // STRUCTDEFINITIONS_INCLUDED