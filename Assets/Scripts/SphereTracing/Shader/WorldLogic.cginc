#ifndef WORLDLOGIC_INCLUDED
#define WORLDLOGIC_INCLUDED

#include "UniformVariables.cginc"       //Contains the resources set from CPU.
#include "ImplicitBasics.cginc"
#include "StructDefinitions.cginc"

//Definition of Material IDs
#define MAT_RED 1.0
#define MAT_BLUE 3.0
#define MAT_GREEN 4.0

#define MAT_BOX 2.0

//Objects in the world.

float2 SphereTest(in float3 pos,float3 translation, float radius, float mat)
{   
    float4x4 m = float4x4(1.0,0.0,0.0,translation.x,
                          0.0,1.0,0.0,translation.y * sin(Time.x), 
                          0.0,0.0,1.0,translation.z, 
                          0.0,0.0,0.0,1.0);
    float3 pt = opTx(pos, m);
    return float2(sdSphere(pt, radius), mat);
}

float2 BoxTest(in float3 pos)
{
    float3 repeating = float3(10.0, 10.0, 10.0);
    float3 posRepeated = mod(pos, repeating) - 0.5 * repeating;
    return float2(sdBox(posRepeated, float3(4.0, 2.0, 1.0)), MAT_BOX);
}

float2 PlaneTest(in float3 pos)
{
    float4x4 m = float4x4(1.0,0.0,0.0,0.0,
                          0.0,1.0,0.0,10.0, 
                          0.0,0.0,1.0,0.0, 
                          0.0,0.0,0.0,1.0);
    float3 pt = opTx(pos, m);
    float plane = sdBox(pt, float3(200.0,2.0,200.0));

    return float2(plane, MAT_BOX); 
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
	float2 res = opU(PlaneTest(pos),SphereTest(pos, float3(0.0,8.0,-8.0), 6.0, MAT_BOX));
    res = opU(res, SphereTest(pos, float3(8.0,1.0,-16.0), 2.0, MAT_RED));
	res = opU(res, SphereTest(pos, float3(-8.0,1.0,-16.0), 2.0, MAT_BLUE));
    res = opU(res, SphereTest(pos, float3(0.0,1.0,0.0), 2.0, MAT_GREEN));

	//float displacement = displacement = sin(5.0 * pos.x) * sin(5.0 * pos.y) * sin(5.0 * pos.z) * 0.25;
	//res += displacement;
	
	return res;
}

void EvaluateMaterial(in Hit hit, in Ray r, in float3 normal, out Material mat)
{
    if (hit.MaterialId < MAT_RED+0.5)
    {
        mat.Color = float3(1, 0, 0);
        mat.Normal = normal;
    } else if (hit.MaterialId < MAT_BOX+0.5)
    {
        mat.Color = float3(.5, .5, .5);
        mat.Normal = normal;
    } else if (hit.MaterialId < MAT_BLUE+0.5)
    {
        mat.Color = float3(0, 0, 1);
        mat.Normal = normal;
    } else if (hit.MaterialId = MAT_GREEN+0.5)
    {
        mat.Color = float3(0, 1, 0);
        mat.Normal = normal;
    }
}

float3 Shading(in Hit hit, in Ray r, in Material mat)
{
    float3 color = float3(.0, .0, .0);

    for(int i = 0; i < LightCount; i++)
    {
        StLightData light = LightBuffer[i];
        if (light.LightType < 0) break;
        if (light.LightType == 0)               // Point Light
        {
            float3 dirToLight = normalize(hit.Position - light.LightData2.xyz);
            float diffuseIntensity = saturate(dot(mat.Normal, dirToLight));
            float3 ambient = float3(.1,.1,.1);
            color += light.LightData.xyz * mat.Color * diffuseIntensity + ambient * mat.Color;
        } else if (light.LightType == 1)        // Directional Light
        {
            float diffuseIntensity = saturate(dot(mat.Normal, light.LightData2.xyz));
            float3 ambient = float3(.1,.1,.1);
            color += light.LightData.xyz * mat.Color * diffuseIntensity + ambient * mat.Color;
        }
    }
    
    return color;
}

float3 Background(in Ray r)
{
    //return r.Direction;
    return float3(.2, .2, .2);
}

#endif // WORLDLOGIC_INCLUDED