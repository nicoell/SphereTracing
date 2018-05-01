#ifndef WORLDLOGIC_INCLUDED
#define WORLDLOGIC_INCLUDED

#include "ImplicitBasics.cginc"

#define MAT_TEST 1.0

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

float2 SphereTest(in float3 pos)
{
    return float2(sdSphere(pos, 3.0), MAT_TEST);
}

/*
 *  Map
 * 
 *  Map containing all the implicit geometry in the world, aka the function calls of signed distance functions.
 *  Returns float2 with:
 *      x: Signed Distance from position to world.
 *      y: MaterialID of object in world.
 */
float2 Map(in float3 pos)
{
	float displacement = 0;
	//displacement = sin(5.0 * pos.x) * sin(5.0 * pos.y) * sin(5.0 * pos.z) * 0.25;

	float2 sphere0 = SphereTest(pos);
	
	return sphere0;
}

void EvaluateMaterial(in float matID, in Ray r, in float3 pos, in float3 normal, out Material mat)
{
    if (matID < MAT_TEST+0.5)
    {
        mat.Color = float3(1, 0, 0);
        mat.Normal = normal;
    }
}

float3 Shading(in float t, in Ray r, in float3 pos, in Material mat)
{
    float3 color = float3(.0, .0, .0);
    //Test Light
    {
        float3 lightPos = float3(2.0, -5.0, 3.0);
        float3 dirToLight = normalize(pos - lightPos);
        
        float diffuseIntensity = saturate(dot(mat.Normal, dirToLight));
        
        color = mat.Color * diffuseIntensity;
    }
    
    return color;
}

float3 Background(in Ray r)
{
    return r.Direction;
    //return float3(.0, .5, .0);
}

#endif // WORLDLOGIC_INCLUDED