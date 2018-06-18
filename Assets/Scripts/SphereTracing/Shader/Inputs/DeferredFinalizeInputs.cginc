#ifndef DEFERREDFINALIZEINPUTS_INCLUDED
#define DEFERREDFINALIZEINPUTS_INCLUDED

#include "../Defines/Structs.cginc"

int RenderOutput;

bool IsFirstPass;
float4 ClearColor;



StructuredBuffer<StLight> LightBuffer;
int LightCount;

float3 CameraDir;

float3 GammaCorrection;
float OcclusionExponent;

#endif // DEFEREDFINALIZEINPUTS_INCLUDED