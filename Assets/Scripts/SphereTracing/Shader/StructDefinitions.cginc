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
    float MaterialId;
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

#endif // STRUCTDEFINITIONS_INCLUDED