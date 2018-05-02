#ifndef WORLDLOGIC_INCLUDED
#define WORLDLOGIC_INCLUDED

#include "ImplicitBasics.cginc"
#include "StructDefinitions.cginc"

//Definition of Material IDs
#define MAT_SPHERE 1.0
#define MAT_BOX 2.0

//Objects in the world.

float2 SphereTest(in float3 pos)
{
    return float2(sdSphere(pos, 3.0), MAT_SPHERE);
}

float2 BoxTest(in float3 pos)
{
    float3 repeating = float3(10.0, 10.0, 10.0);
    float3 posRepeated = mod(pos, repeating) - 0.5 * repeating;
    return float2(sdBox(posRepeated, float3(4.0, 2.0, 1.0)), MAT_BOX);
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
	float2 res = opU(BoxTest(pos), SphereTest(pos));
	
	//float displacement = displacement = sin(5.0 * pos.x) * sin(5.0 * pos.y) * sin(5.0 * pos.z) * 0.25;
	//res += displacement;
	
	return res;
}

void EvaluateMaterial(in float matID, in Ray r, in float3 pos, in float3 normal, out Material mat)
{
    if (matID < MAT_SPHERE+0.5)
    {
        mat.Color = float3(1, 0, 0);
        mat.Normal = normal;
    } else if (matID = MAT_BOX+0.5)
    {
        mat.Color = float3(1, 1, 1);
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