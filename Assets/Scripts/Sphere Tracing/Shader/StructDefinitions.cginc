#ifndef STRUCTDEFINITIONS_INCLUDED
#define STRUCTDEFINITIONS_INCLUDED

struct Ray
{
    float3 Origin;
    float3 Direction;
};

struct Material
{
    float3 Color;
    float3 Normal;
};

#endif // STRUCTDEFINITIONS_INCLUDED