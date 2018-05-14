#ifndef STRUCTDEFINITIONS_INCLUDED
#define STRUCTDEFINITIONS_INCLUDED

struct Ray
{
    float3 Origin;
    float3 Direction;
};

struct Hit
{
    float3 Position;
    float TraceDistance;
    int MaterialId;
    float DistanceToWorld;
};

struct Material
{
    float3 Color;
    float ReflectiveF;
    float3 Normal;
};

struct StLightData
{
    int LightType;
    float4 LightData;
    float4 LightData2;
};

struct StMaterialData
{
    int MaterialType;
    float4 Color;
    float Roughness;
};

#endif // STRUCTDEFINITIONS_INCLUDED