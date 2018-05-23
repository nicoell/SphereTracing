#ifndef DEFERREDRENDERINGINPUTS_INCLUDED
#define DEFERREDRENDERINGINPUTS_INCLUDED

int SurfaceDataStep;
int DepthStep;
int AmbientOcclusionStep;

/*
 * All Textures with its dimension * k, used for reflections or transparency
 * 
 * SurfaceData stores information of:
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
 * DeferredProcess upscales and filters AmbientOcclusion and writes it in SurfaceData Texture
 */

#ifdef DEFERRED_CREATE
    //Write into targets;
    RWTexture2DArray<float4> SurfaceDataTarget;
    RWTexture2DArray<float4> AmbientOcclusionTarget;
    RWTexture2DArray<float> DepthTarget;
#elif DEFERRED_PROCESS
    //Read from targets, process and write in Deferred
    Texture2DArray<float4> SurfaceDataTarget;
    Texture2DArray<float4> AmbientOcclusionTarget;
    Texture2DArray<float> DepthTarget;
    
    RWTexture2DArray<float4> SurfaceDataDeferred;
    RWTexture2DArray<float4> AmbientOcclusionDeferred;
    RWTexture2DArray<float> DepthDeferred;
#elif DEFERRED_FINALIZE
    //Read from Deferred and write into Output
    Texture2DArray<float4> SurfaceDataDeferred;
    Texture2DArray<float4> AmbientOcclusionDeferred;
    Texture2DArray<float> DepthDeferred;
    SamplerState sampler_linear_clamp;
    
    RWTexture2D<float4> DeferredOutput;
#endif


#endif // DEFERREDRENDERINGINPUTS_INCLUDED