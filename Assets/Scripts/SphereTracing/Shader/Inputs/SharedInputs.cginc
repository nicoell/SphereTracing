#ifndef SHAREDINPUTS_INCLUDED
#define SHAREDINPUTS_INCLUDED

#include "../Defines/Structs.cginc"

StructuredBuffer<StMaterial> MaterialBuffer;
int MaterialCount;

float2 AngleBetweenRays;

bool EnableAmbientOcclusion;
bool EnableGlobalIllumination;

float AoTargetMip;
float2 ClippingPlanes;                      //x: Near        y: Far    
float2 Resolution;      //Width and Height of RenderTexture
float2 AoResolution;    //Width and Height of Ambient Occlusion Texture
float4 Time;            //x: Time in s   y: x/20     z: deltaTime      w: 1/z

#endif // SHAREDINPUTS_INCLUDED