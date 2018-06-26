#ifndef STRUCTLOADFUNCS_INCLUDED
#define STRUCTLOADFUNCS_INCLUDED

#include "Defines/Structs.cginc"
#include "Inputs/TextureAccessAwareInputs.cginc"

/*
 * Description of parameters:
 * uint2 xy:     The xy coordinate of a pixel to index a texture.
 * uint k:       The k-layer to index the coordinate texturearray depth, 0 for surface, 1 for represent.
 */

/*
 * Load functions to ease reading of texture data with an index.
 * - Only define functions if corresponing (R)ead or (R)ead(W)rite defines are set.
 */

#if defined(ST_R) || defined(ST_RW)
    SphereTracingData LoadSphereTracingData(in uint2 xy, in uint k)
    {
        SphereTracingData stData;
        stData.Position = SphereTracingDataTexture[uint3(xy, k*3 + 0)].xyz;
        stData.MaterialId = (int) SphereTracingDataTexture[uint3(xy, k*3 + 0)].w;
        stData.RayDirection = SphereTracingDataTexture[uint3(xy, k*3 + 1)].xyz;
        stData.TraceDistance = SphereTracingDataTexture[uint3(xy, k*3 + 1)].w;
        stData.Normal = SphereTracingDataTexture[uint3(xy, k*3 + 2)].xyz;
        stData.Alpha = SphereTracingDataTexture[uint3(xy, k*3 + 2)].w;
        return stData;
    }
    
    Ray LoadRay(in uint2 xy, in uint k)
    {
        Ray r;
        r.Origin = SphereTracingDataTexture[uint3(xy, k*3 + 0)].xyz;
        r.Direction = SphereTracingDataTexture[uint3(xy, k*3 + 1)].xyz;
        return r;
    }
    
    float LoadAlpha(in uint2 xy, in uint k)
    {
        return SphereTracingDataTexture[uint3(xy, k*3 + 2)].w;
    }
    
    float3 LoadNormal(in uint2 xy, in uint k)
    {
        return SphereTracingDataTexture[uint3(xy, k*3 + 2)].xyz;
    }
     
    float LoadTraceDistance(in uint2 xy, in uint k)
    {
        return SphereTracingDataTexture[uint3(xy, k*3 + 1)].w;
    } 
#endif
    
#if defined(AO_R) || defined(AO_RW)
    AmbientOcclusion LoadAmbientOcclusion(in uint2 xy, in uint k)
    {
        AmbientOcclusion ao;
        ao.BentNormal = AmbientOcclusionTexture[uint3(xy, k)].xyz;
        ao.SpecularOcclusion = AmbientOcclusionTexture[uint3(xy, k)].w;
        return ao;
    }
    
    float4 LoadAmbientOcclusionAsFloat4(in uint2 xy, in uint k)
    {
        float4 ao;
        ao.xyz = AmbientOcclusionTexture[uint3(xy, k)].xyz;
        ao.w = AmbientOcclusionTexture[uint3(xy, k)].w;
        return ao;
    }
#endif

#endif // STRUCTLOADFUNCS_INCLUDED