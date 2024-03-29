#ifndef WORLDLOGIC_INCLUDED
#define WORLDLOGIC_INCLUDED

#include "Defines/SharedConstants.cginc"
#include "Inputs/SharedInputs.cginc"
#include "Utils/ImplicitBasics.cginc" 

//Definition of Material IDs
#define MAT_RED 0
#define MAT_GREEN 1
#define MAT_BLUE 2
#define MAT_FLOOR 3
#define MAT_WALLS 4

//Baked Matrices
static const float4x4 M_IDENTITY =
float4x4(1, 0, 0, 0, 
0, 1, 0, 0, 
0, 0, 1, 0, 
0, 0, 0, 1); 

static const float4x4 M_LEFTWALL =
float4x4(1, 0, 0, 2, 
0, 1, 0, 6, 
0, 0, 1, 0, 
0, 0, 0, 1); 
 
static const float4x4 M_WALLHOLE1 =
float4x4(1, 0, 0, -6, 
0, -4.371139E-08, -1, -2.84124E-07, 
0, 1, -4.371139E-08, 6.5, 
0, 0, 0, 1); 
 
static const float4x4 M_WALLHOLE2 =
float4x4(1, 0, 0, -2.5, 
0, -4.371139E-08, -1, -2.84124E-07, 
0, 1, -4.371139E-08, 6.5, 
0, 0, 0, 1); 
 
static const float4x4 M_WALLHOLE3 =
float4x4(1, 0, 0, 1, 
0, -4.371139E-08, -1, -2.84124E-07, 
0, 1, -4.371139E-08, 6.5, 
0, 0, 0, 1); 
 
static const float4x4 M_LEFTWALL2 =
float4x4(1, 0, 0, -8, 
0, 1, 0, 6, 
0, 0, 1, 9, 
0, 0, 0, 1); 
 
static const float4x4 M_RIGHTWALL =
float4x4(1, 0, 0, 2, 
0, 1, 0, 6, 
0, 0, 1, -6, 
0, 0, 0, 1); 
 
static const float4x4 M_ROOF =
float4x4(1, 0, 0, 3, 
0, 1, 0, 4.5, 
0, 0, 1, -2, 
0, 0, 0, 1); 
 
static const float4x4 M_PILLAR1 =
float4x4(1, 0, 0, 10, 
0, 1, 0, 6.5, 
0, 0, 1, -3, 
0, 0, 0, 1); 
 
static const float4x4 M_PILLAR2 =
float4x4(1, 0, 0, 7, 
0, 1, 0, 6.5, 
0, 0, 1, -3, 
0, 0, 0, 1); 
 
static const float4x4 M_PILLAR3 =
float4x4(1, 0, 0, 4, 
0, 1, 0, 6.5, 
0, 0, 1, -3, 
0, 0, 0, 1); 
 
static const float4x4 M_PILLAR4 =
float4x4(1, 0, 0, 1, 
0, 1, 0, 6.5, 
0, 0, 1, -3, 
0, 0, 0, 1); 
 
static const float4x4 M_PILLAR5 =
float4x4(1, 0, 0, -2, 
0, 1, 0, 6.5, 
0, 0, 1, -3, 
0, 0, 0, 1); 
 
static const float4x4 M_PILLAR6 =
float4x4(1, 0, 0, -5, 
0, 1, 0, 6.5, 
0, 0, 1, -3, 
0, 0, 0, 1); 
 
static const float4x4 M_SPHERE =
float4x4(1, 0, 0, -5, 
0, 1, 0, 7, 
0, 0, 1, -4, 
0, 0, 0, 1); 
 
static const float4x4 M_BB =
float4x4(1, 0, 0, 1.75, 
0, 1, 0, 6, 
0, 0, 1, 6, 
0, 0, 0, 1); 
 
//Objects in the world.
float PlateTexture(float3 pos, uniform float4 plateSettings)
{   
    float distanceToCamera = length(pos - CameraPos);
    if (distanceToCamera > plateSettings.w) return 0;
     
    float disp = 0;
    float dist = plateSettings.x;
    float size = plateSettings.y;
    float depth = plateSettings.z;
    
    float m = min(min(abs(pos.x) % dist, abs(pos.y) % dist), abs(pos.z) % dist);
    disp += (m < size) ? depth : 0;

    return disp * (1 - saturate(length(pos - CameraPos) / plateSettings.w));
}

float2 FloorPlane(in float3 pos, in float offset, in float mat){
    return float2(pos.y + offset + PlateTexture(pos, PlateTextureSettings), mat);
}

float2 Cylinder(float3 pos, float2 h, float4x4 M, float mat)
{
    pos = opTx(pos, M);
    return float2(sdCappedCylinder(pos, h), mat);
}

float2 Box(float3 pos, float3 d, float4x4 M, float mat)
{
    pos = opTx(pos, M);
    return float2(sdBox(pos, d), mat);
}

float2 Sphere(float3 pos, float rad, float4x4 M, float mat)
{
    pos = opTx(pos, M);
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
	float2 res;
    //floor
	float2 floor = FloorPlane(pos, 8, MAT_FLOOR);
	
	/*Bounding Box Test
    loat2 bb = Box(pos, float3(10.25, 2, 13), M_BB, -1);
    if (bb.x > 0.1) {
        res = floor;
        return opU(floor, bb);
    }*/
    
    //left wall
    float2 wall = Box(pos, float3(10,2,1), M_LEFTWALL, MAT_WALLS);
    //leftwall 2
    wall = opU(wall, Box(pos, float3(.5,2,10), M_LEFTWALL2, MAT_WALLS));
    //rightwall
    wall = opU(wall, Box(pos, float3(10,2,1), M_RIGHTWALL, MAT_WALLS));
    //roof
    wall = opU(wall, Box(pos, float3(9,.5,3), M_ROOF, MAT_WALLS));

    res = opU(floor, wall);
    res.x += PlateTexture(pos, PlateTextureSettings);
    //holes in left wall
    res = opS(Cylinder(pos, float2(1.2,2.0), M_WALLHOLE1, MAT_GREEN), res);
    res = opS(Cylinder(pos, float2(1.2,2.0), M_WALLHOLE2, MAT_GREEN), res);
    res = opS(Cylinder(pos, float2(1.2,2.0), M_WALLHOLE3, MAT_GREEN), res);

    //pillars
    res = opU(res, Box(pos, float3(.2,1.5,.2), M_PILLAR1, MAT_BLUE));
    res = opU(res, Box(pos, float3(.2,1.5,.2), M_PILLAR2, MAT_BLUE));
    res = opU(res, Box(pos, float3(.2,1.5,.2), M_PILLAR3, MAT_BLUE));
    res = opU(res, Box(pos, float3(.2,1.5,.2), M_PILLAR4, MAT_BLUE));
    res = opU(res, Box(pos, float3(.2,1.5,.2), M_PILLAR5, MAT_BLUE));
    res = opU(res, Box(pos, float3(.2,1.5,.2), M_PILLAR6, MAT_BLUE));

    //spheres
    //res = opU(res, Sphere(pos, .2, M_SPHERE, MAT_GREEN));
    
    float2 dynamicObjects;
    for(int i = 0; i < MatrixCount; i++)
    {
        float4x4 m = MatrixBuffer[i].Matrix;
        
        float size = smin(abs(res.x), 1.0, 0.1);
        float2 temp = Sphere(pos, size, m, MAT_RED);
        dynamicObjects = (i == 0) ? temp : opUSmooth(dynamicObjects, temp, 0.1);
    }
    
    dynamicObjects.x += 0.4 * sin(pos.x*3) * sin(pos.y*3) * sin(pos.z*3);                    //Add low freq offset
    dynamicObjects.x += 0.05 * cos(20.0*pos.x) * cos(20.0*pos.y) * cos(20.0*pos.z);     //Add high freq offset
    res = (MatrixCount > 0) ? opU(res, dynamicObjects) : res;
        
	return res;
}

float MapLite(in float3 pos)
{   
	float2 res;
    //floor
	float2 floor = FloorPlane(pos, 8, MAT_FLOOR);
	    
    //left wall
    float2 wall = Box(pos, float3(10,2,1), M_LEFTWALL, MAT_WALLS);
    //leftwall 2
    wall = opU(wall, Box(pos, float3(.5,2,10), M_LEFTWALL2, MAT_WALLS));
    //rightwall
    wall = opU(wall, Box(pos, float3(10,2,1), M_RIGHTWALL, MAT_WALLS));
    //roof
    wall = opU(wall, Box(pos, float3(9,.5,3), M_ROOF, MAT_WALLS));

    res = opU(floor, wall);
    //holes in left wall
    res = opS(Cylinder(pos, float2(1.2,2.0), M_WALLHOLE1, MAT_GREEN), res);
    res = opS(Cylinder(pos, float2(1.2,2.0), M_WALLHOLE2, MAT_GREEN), res);
    res = opS(Cylinder(pos, float2(1.2,2.0), M_WALLHOLE3, MAT_GREEN), res);

    //pillars
    res = opU(res, Box(pos, float3(.2,1.5,.2), M_PILLAR1, MAT_BLUE));
    res = opU(res, Box(pos, float3(.2,1.5,.2), M_PILLAR2, MAT_BLUE));
    res = opU(res, Box(pos, float3(.2,1.5,.2), M_PILLAR3, MAT_BLUE));
    res = opU(res, Box(pos, float3(.2,1.5,.2), M_PILLAR4, MAT_BLUE));
    res = opU(res, Box(pos, float3(.2,1.5,.2), M_PILLAR5, MAT_BLUE));
    res = opU(res, Box(pos, float3(.2,1.5,.2), M_PILLAR6, MAT_BLUE));

    float2 dynamicObjects;
    for(int i = 0; i < MatrixCount; i++)
    {
        float4x4 m = MatrixBuffer[i].Matrix;
        
        float size = smin(abs(res.x), 1.0, 0.1);
        float2 temp = Sphere(pos, size, m, MAT_RED);
        dynamicObjects = (i == 0) ? temp : opU(dynamicObjects, temp);
    }
    
    dynamicObjects.x += 0.4 * sin(pos.x*3) * sin(pos.y*3) * sin(pos.z*3);                    //Add low freq offset
    res = (MatrixCount > 0) ? opU(res, dynamicObjects) : res;
        
	return res.x;
}

/*


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
    t = -t;
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


float2 MapOld(in float3 pos)
{   
    //floor
	float2 res = PlaneTest(pos);
    //left wall
    float2 wall = Box(pos, float3(10,2,1), float3(-2,-6,0), float3(0,0,0), MAT_FLOOR);
    //holes in left wall
    wall = opS(Cylinder(pos, float2(1.2,1.2), float3(6,-6.5,0), float3(PI/2,0,0), MAT_FLOOR), wall);
    wall = opS(Cylinder(pos, float2(1.2,1.2), float3(2.5,-6.5,0), float3(PI/2,0,0), MAT_FLOOR), wall);
    wall = opS(Cylinder(pos, float2(1.2,1.2), float3(-1,-6.5,0), float3(PI/2,0,0), MAT_FLOOR), wall);
    //leftwall 2
    wall = opU(wall, Box(pos, float3(.5,2,10), float3(8,-6,-9), float3(0,0,0), MAT_FLOOR));

    res = opU(res,wall);

    //right wall
    res = opU(res, Box(pos, float3(10,2,1), float3(-2,-6,6), float3(0,0,0), MAT_FLOOR));
    //roof
    res = opU(res, Box(pos, float3(9,.5,3), float3(-3,-4.5,2), float3(0,0,0), MAT_FLOOR));
    //pillars
    res = opU(res, Box(pos, float3(.2,1.5,.2), float3(-10,-6.5,3), float3(0,0,0), MAT_FLOOR));
    res = opU(res, Box(pos, float3(.2,1.5,.2), float3(-7,-6.5,3), float3(0,0,0), MAT_FLOOR));
    res = opU(res, Box(pos, float3(.2,1.5,.2), float3(-4,-6.5,3), float3(0,0,0), MAT_FLOOR));
    res = opU(res, Box(pos, float3(.2,1.5,.2), float3(-1,-6.5,3), float3(0,0,0), MAT_FLOOR));
    res = opU(res, Box(pos, float3(.2,1.5,.2), float3(2,-6.5,3), float3(0,0,0), MAT_FLOOR));
    res = opU(res, Box(pos, float3(.2,1.5,.2), float3(5,-6.5,3), float3(0,0,0), MAT_FLOOR));

    //spheres
    res = opU(res, Sphere(pos, .2, float3(5,-7,4), float3(0,0,0), MAT_GREEN));
	return res;
}
*/
#endif // WORLDLOGIC_INCLUDED