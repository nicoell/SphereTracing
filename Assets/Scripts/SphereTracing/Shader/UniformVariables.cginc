#ifndef UNIFORMVARIABLES_INCLUDED
#define UNIFORMVARIABLES_INCLUDED

#include "StructDefinitions.cginc"

/*
 * Variables set from CPU side, like uniforms
 */
RWTexture2D<float4> SphereTracingTexture;   //Target Render Texture with Read Write Access
StructuredBuffer<StLight> LightBuffer;
StructuredBuffer<StMaterial> MaterialBuffer;

float4 CameraFrustumEdgeVectors[4];         //Array of the cameras frustum edge vectors, clockwise beginning in the topleft.
float4x4 CameraInverseViewMatrix;       
float3 CameraPos;   
float2 Resolution;                          //Width and Height of RenderTexture
float2 ClippingPlanes;                      //x: Near        y: Far
float4 Time;                                //x: Time in s   y: x/20     z: deltaTime      w: 1/z

int MaterialCount;
int LightCount;
int SphereTracingSteps;
int AmbientOcclusionSamples;
bool EnableSuperSampling;

#endif // UNIFORMVARIABLES_INCLUDED