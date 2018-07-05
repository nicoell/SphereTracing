#ifndef DEFERREDSHADINGINPUTS_INCLUDED
#define DEFERREDSHADINGINPUTS_INCLUDED

#include "../Defines/Structs.cginc"

int RenderOutput;

bool IsFirstPass;
float4 ClearColor;

bool EnableAmbientOcclusion;
bool EnableGlobalIllumination;

bool EnableCubemap;
TextureCube<float4> Cubemap;
SamplerState sampler_Cubemap;

StructuredBuffer<StMaterial> MaterialBuffer;
int MaterialCount;
StructuredBuffer<StLight> LightBuffer;
int LightCount;

float3 CameraDir;

float3 GammaCorrection;
float OcclusionExponent;

#endif // DEFEREDFINALIZEINPUTS_INCLUDED