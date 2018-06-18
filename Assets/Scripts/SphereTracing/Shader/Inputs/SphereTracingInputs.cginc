#ifndef SPHERETRACINGINPUT_INCLUDED
#define SPHERETRACINGINPUT_INCLUDED



float4 CameraFrustumEdgeVectors[4];         //Array of the cameras frustum edge vectors, clockwise beginning in the topleft.
float4x4 CameraInverseViewMatrix;       
float3 CameraPos;

float RadiusPixel;
int SphereTracingSteps;
bool EnableSuperSampling;


int AmbientOcclusionSamples;
int AmbientOcclusionSteps;
float AmbientOcclusionMaxDistance;
float SpecularOcclusionStrength;
float BentNormalFactor;

#endif // SPHERETRACINGINPUT_INCLUDED