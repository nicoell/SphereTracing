#ifndef WORLDLOGIC_INCLUDED
#define WORLDLOGIC_INCLUDED


#include "Utils/ImplicitBasics.cginc" 



//Definition of Material IDs
#define MAT_RED 0
#define MAT_GREEN 1
#define MAT_BLUE 2
#define MAT_FLOOR 3

//Objects in the world.
float PlateTexture(float3 pos, float dist, float size, float depth)
{   
    float disp = 0;

    disp += (pos.x%dist < size) ? depth : 0;
    disp += (pos.y%dist < size) ? depth : 0;
    disp += (pos.z%dist < size) ? depth : 0;

    return disp;
}

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

float2 SphereTest(in float3 pos, float3 translation, float radius, float mat)
{   
	float4x4 m = float4x4(1.0,0.0,0.0,translation.x,
						  0.0,1.0,0.0,translation.y, 
						  0.0,0.0,1.0,translation.z, 
						  0.0,0.0,0.0,1.0);
	float3 pt = opTx(pos, m);
    
	return float2(sdSphere(pt, radius), mat);
}

float2 PlaneTest(in float3 pos)
{
	float4x4 m = float4x4(1.0,0.0,0.0,10.0,
						  0.0,1.0,0.0,10.0, 
						  0.0,0.0,1.0,0.0, 
						  0.0,0.0,0.0,1.0);
	float3 pt = opTx(pos, m);
   	float plane = sdBox(pt, float3(400.0,2.0,400.0));
    plane += PlateTexture(pos, 1.0, .0075, .0025);
	return float2(plane, MAT_FLOOR); 
}


//Finalized methods from here on 
float4x4 GetTxMatrix(in float3 t, in float3 r)
{   

    float4x4 tm = float4x4(1.0, 0.0, 0.0, t.x, 
                            0.0, 1.0, 0.0, t.y,
                            0.0, 0.0, 1.0, t.z,
                            0.0, 0.0, 0.0, 1.0);

    if(r.x == 0 && r.y == 0 && r.z == 0) return tm;

    float4x4 rx = float4x4(1.0, 0.0, 0.0, 0.0,
                           0.0, cos(r.x), -sin(r.x), 0.0, 
                           0.0, sin(r.x), cos(r.x), 0.0, 
                           0.0, 0.0, 0.0, 1.0);

    float4x4 ry = float4x4(cos(r.y), 0.0, sin(r.y), 0.0,
                            0.0, 1.0, 0.0, 0.0,
                            -sin(r.y), 0.0, cos(r.y), 0.0,
                            0.0, 0.0, 0.0, 1.0);

    float4x4 rz = float4x4(cos(r.z), -sin(r.z), 0.0, 0.0,
                            sin(r.z), cos(r.z), 0.0, 0.0,
                            0.0, 0.0, 1.0, 0.0,
                            0.0, 0.0, 0.0, 1.0);

    float4x4 fm = mul(rx, tm);
    ;

    return fm;
}

float2 Cylinder(float3 pos, float2 h, float3 t, float3 r, float mat)
{
    float4x4 m = GetTxMatrix(t,r);
    pos = opTx(pos, m);
    return float2(sdCappedCylinder(pos, h), mat);
}

float2 Box(float3 pos, float3 d, float3 t, float3 r, float mat)
{
    float4x4 m = GetTxMatrix(t,r);
    pos = opTx(pos, m);
    return float2(sdBox(pos, d) + PlateTexture(pos, 1.0, .0075, .0025), mat);
}

float2 Sphere(float3 pos, float rad, float3 t, float3 r, float mat)
{
    float4x4 m = GetTxMatrix(t,r);
    pos = opTx(pos, m);
    return float2(sdSphere(pos, rad), mat);
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
    //floor
	float2 res = PlaneTest(pos);
    //left wall
    float2 wall = Box(pos, float3(10,2,1), float3(2,6,0), float3(0,0,0), MAT_FLOOR);
    wall = opS(Cylinder(pos, float2(1.2,1.2), float3(-6,6.5,0), float3(PI/2,0,0), MAT_FLOOR), wall);
    wall = opS(Cylinder(pos, float2(1.2,1.2), float3(-2.5,6.5,0), float3(PI/2,0,0), MAT_FLOOR), wall);
    wall = opS(Cylinder(pos, float2(1.2,1.2), float3(1,6.5,0), float3(PI/2,0,0), MAT_FLOOR), wall);
    wall = opU(wall, Box(pos, float3(.5,2,10), float3(-8,6,9), float3(0,0,0), MAT_FLOOR));

    res = opU(res,wall);

    //right wall
    res = opU(res, Box(pos, float3(10,2,1), float3(2,6,-6), float3(0,0,0), MAT_FLOOR));
    //pillars
    res = opU(res, Box(pos, float3(9,.5,3), float3(3,4.5,-2), float3(0,0,0), MAT_FLOOR));
    res = opU(res, Box(pos, float3(.2,1.5,.2), float3(10,6.5,-3), float3(0,0,0), MAT_FLOOR));
    res = opU(res, Box(pos, float3(.2,1.5,.2), float3(7,6.5,-3), float3(0,0,0), MAT_FLOOR));
    res = opU(res, Box(pos, float3(.2,1.5,.2), float3(4,6.5,-3), float3(0,0,0), MAT_FLOOR));
    res = opU(res, Box(pos, float3(.2,1.5,.2), float3(1,6.5,-3), float3(0,0,0), MAT_FLOOR));
    res = opU(res, Box(pos, float3(.2,1.5,.2), float3(-2,6.5,-3), float3(0,0,0), MAT_FLOOR));
    res = opU(res, Box(pos, float3(.2,1.5,.2), float3(-5,6.5,-3), float3(0,0,0), MAT_FLOOR));


    //spheres
    res = opU(res, Sphere(pos, .2, float3(-5,7,-4), float3(0,0,0), MAT_GREEN));
	return res;
}

#include "AmbientOcclusion.cginc"
/*
void EvaluateMaterial(inout Hit hit, in Ray r, in float3 normal)
{
	hit.Material = MaterialBuffer[hit.MaterialId];
	
	if (hit.Material.MaterialType == 0) {
		hit.Normal = normal;
	}
}

*/

#endif // WORLDLOGIC_INCLUDED