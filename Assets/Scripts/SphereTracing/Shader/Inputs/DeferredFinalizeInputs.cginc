#ifndef DEFERREDFINALIZEINPUTS_INCLUDED
#define DEFERREDFINALIZEINPUTS_INCLUDED

#include "../Defines/Structs.cginc"

bool EnableAmbientOcclusion;
bool EnableGlobalIllumination;

StructuredBuffer<StMaterial> MaterialBuffer;
StructuredBuffer<StLight> LightBuffer;
int LightCount;

float3 CameraDir;

float3 GammaCorrection;
float OcclusionExponent;

#endif // DEFEREDFINALIZEINPUTS_INCLUDED