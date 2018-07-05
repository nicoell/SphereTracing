#ifndef SPHERETRACINGINPUT_INCLUDED
#define SPHERETRACINGINPUT_INCLUDED

#include "../Defines/Structs.cginc"

StructuredBuffer<StMaterial> MaterialBuffer;

float4 CameraFrustumEdgeVectors[4];         //Array of the cameras frustum edge vectors, clockwise beginning in the topleft.
float4x4 CameraInverseViewMatrix;       

float RadiusPixel;
int MaterialCount;
int SphereTracingSteps;
bool EnableSuperSampling;

StructuredBuffer<float3> AoSampleBuffer;
bool EnableAmbientOcclusion;
int AmbientOcclusionSamples;
int AmbientOcclusionSteps;
float AmbientOcclusionMaxDistance;
float SpecularOcclusionStrength;
float BentNormalFactor;
float ConeAngle;

#endif // SPHERETRACINGINPUT_INCLUDED