#ifndef SPHERETRACINGINPUT_INCLUDED
#define SPHERETRACINGINPUT_INCLUDED

#include "../Defines/Structs.cginc"

StructuredBuffer<StMaterial> MaterialBuffer;

float4 CameraFrustumEdgeVectors[4];         //Array of the cameras frustum edge vectors, clockwise beginning in the topleft.
float4x4 CameraInverseViewMatrix;       
float3 CameraPos;   
float3 CameraDir;   
float2 ClippingPlanes;                      //x: Near        y: Far    

float RadiusPixel;
int MaterialCount;
int SphereTracingSteps;
bool EnableSuperSampling;

bool EnableAmbientOcclusion;
int AmbientOcclusionSamples;
int AmbientOcclusionSteps;
float AmbientOcclusionMaxDistance;
float SpecularOcclusionStrength;
float OcclusionExponent;
float BentNormalFactor;
bool EnableGlobalIllumination;

float3 GammaCorrection;

#endif // SPHERETRACINGINPUT_INCLUDED