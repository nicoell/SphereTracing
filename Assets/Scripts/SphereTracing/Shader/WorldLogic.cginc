#ifndef WORLDLOGIC_INCLUDED
#define WORLDLOGIC_INCLUDED

#include "Utils/ImplicitBasics.cginc" 
#include "Inputs/SharedInputs.cginc"

//Definition of Material IDs
#define MAT_RED 0
#define MAT_GREEN 1
#define MAT_BLUE 2
#define MAT_FLOOR 3

//Objects in the world.

float2 AOTorus(in float3 pos, float mat)
{
	
	float4x4 m = float4x4(1.0,0.0,0.0,0.0,
						  0.0,1.0,0.0,8, 
						  0.0,0.0,1.0,0.0, 
						  0.0,0.0,0.0,1.0);
	float3 p = opTx(pos, m);
	
	float2 q = float2(length(p.xz) - 30., p.y);
	
	return float2(length(q) - 2., mat);
}

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
	return float2(sdBox(posRepeated, float3(4.0, 2.0, 1.0)), MAT_RED);
}

float2 PlaneTest(in float3 pos)
{
	float4x4 m = float4x4(1.0,0.0,0.0,0.0,
						  0.0,1.0,0.0,10.0, 
						  0.0,0.0,1.0,0.0, 
						  0.0,0.0,0.0,1.0);
	float3 pt = opTx(pos, m);
	float plane = sdBox(pt, float3(200.0,2.0,200.0));

	return float2(plane, MAT_FLOOR); 
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
    float2 a = SphereTest(pos, float3(8.0,1.0,-8.0), 2.0, MAT_RED);
    float2 b = SphereTest(pos, float3(6.0,1.0,-8.0), 3.0, MAT_RED);

	float2 res = opU(PlaneTest(pos),SphereTest(pos, float3(0.0,8.0,0.0), 6.0, MAT_RED));
	res = opU(res, opS(a, b));
	res = opU(res, SphereTest(pos, float3(-8.0,1.0,-8.0), 2.0, MAT_BLUE));
	res = opU(res, SphereTest(pos, float3(0.0,1.0,8.0), 2.0, MAT_GREEN));
	res = opU(res, AOTorus(pos, MAT_FLOOR));
	//float displacement = displacement = sin(5.0 * pos.x) * sin(5.0 * pos.y) * sin(5.0 * pos.z) * 0.25;
	//res += displacement;
	
	return res;
}


#endif // WORLDLOGIC_INCLUDED