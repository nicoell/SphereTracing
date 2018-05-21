#ifndef UNIFORMVARIABLES_INCLUDED
#define UNIFORMVARIABLES_INCLUDED

#include "StructDefinitions.cginc"

/*
 * Constants
 */
static const float PI = 3.141592653589793238;
static const float GOLDENRATIO = 1.6180339887498948;//Golden Ratio = (1 + sqrt(5)) / 2
static const float GOLDENANGLE = 2.4;               //Golden Angle = PI (3 - sqrt(5)) 

/*
 * Variables set from CPU side, like uniforms
 */
RWTexture2D<float4> SphereTracingTexture;   //Target Render Texture with Read Write Access
StructuredBuffer<StLight> LightBuffer;
StructuredBuffer<StMaterial> MaterialBuffer;

float4 CameraFrustumEdgeVectors[4];         //Array of the cameras frustum edge vectors, clockwise beginning in the topleft.
float4x4 CameraInverseViewMatrix;       
float3 CameraPos;   
float3 CameraDir;   
float2 Resolution;                          //Width and Height of RenderTexture
float2 ClippingPlanes;                      //x: Near        y: Far
float4 Time;                                //x: Time in s   y: x/20     z: deltaTime      w: 1/z

int MaterialCount;
int LightCount;
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

#endif // UNIFORMVARIABLES_INCLUDED