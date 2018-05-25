#ifndef DEFERREDRENDERINGINPUTS_INCLUDED
#define DEFERREDRENDERINGINPUTS_INCLUDED

//int SphereTracingDataStep;
//int DepthStep;
//int AmbientOcclusionStep;

/*
 * All Textures with its dimension * k, used for reflections or transparency
 * 
 * SphereTracingData stores information of:
 * Surface Hit:
 * [0] Position.xyz, MaterialId
 * [1] Normal.xyz, Alpha
 * Representative Hit:
 * [2] Position.xyz, MaterialId
 * [3] Normal.xyz, Alpha
 *
 * AmbientOcclusionTarget stores information of:
 * Surface Hit:
 * [0] BentNormal.xyz, SpecularOcclusion
 * Representative Hit:
 * [1] BentNormal.xyz, SpecularOcclusion
 *
 * DepthTarget stores information of:
 * Surface Hit:
 * [0] TraceDistance
 * Representative Hit:
 * [1] TraceDistance
 *
 * DeferredProcess upscales and filters AmbientOcclusion and writes it in SphereTracingData Texture
 */

#ifdef ST_RW
    //SphereTracing ReadWrite
    RWTexture2DArray<float4> SphereTracingDataTexture;
#elif ST_R
    //SphereTracing Read
    Texture2DArray<float4> SphereTracingDataTexture;
#endif

#ifdef AO_RW
    RWTexture2DArray<float4> AmbientOcclusionTexture;
#elif AO_R
    Texture2DArray<float4> AmbientOcclusionTexture;
#endif

#ifdef DEF_RW
    RWTexture2D<float4> DeferredOutputTexture;
#endif

SamplerState sampler_linear_clamp;


#endif // DEFERREDRENDERINGINPUTS_INCLUDED