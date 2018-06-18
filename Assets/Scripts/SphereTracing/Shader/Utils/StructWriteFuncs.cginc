#ifndef STRUCTWRITEFUNCS_INCLUDED
#define STRUCTWRITEFUNCS_INCLUDED

#include "Defines/Structs.cginc"
#include "Inputs/TextureAccessAwareInputs.cginc"

/*
 * Description of parameters:
 * uint2 xy:     The xy coordinate of a pixel to index a texture.
 * uint k:       The k-layer to index the coordinate texturearray depth, 0 for surface, 1 for represent.
 */

/*
 * Write functions to ease write of data in textures.
 * - Only define functions if corresponing (R)ead(W)rite define is set. 
 */

#ifdef ST_RW
    void WriteSphereTracingData(in uint2 xy, in uint k, in SphereTracingData stData)
    {
        SphereTracingDataTexture[uint3(xy, k*3 + 0)] = float4(stData.Position, stData.MaterialId);
        SphereTracingDataTexture[uint3(xy, k*3 + 1)] = float4(stData.RayDirection, stData.TraceDistance);
        SphereTracingDataTexture[uint3(xy, k*3 + 2)] = float4(stData.Normal, stData.Alpha);
    }
#endif

#ifdef ST_LOW_RW
    void WriteSphereTracingDataLow(in uint2 xy, in uint k, in SphereTracingData stData)
    {
        SphereTracingDataLowTexture[uint3(xy, k*3 + 0)] = float4(stData.Position, stData.MaterialId);
        SphereTracingDataLowTexture[uint3(xy, k*3 + 1)] = float4(stData.RayDirection, stData.TraceDistance);
        SphereTracingDataLowTexture[uint3(xy, k*3 + 2)] = float4(stData.Normal, stData.Alpha);
    }
#endif
    
#ifdef AO_RW
    void WriteAmbientOcclusion(in uint2 xy, in uint k, in AmbientOcclusion ao)
    {
        AmbientOcclusionTexture[uint3(xy, k)] = float4(ao.BentNormal, ao.SpecularOcclusion);
    }
#endif

#endif // STRUCTWRITEFUNCS_INCLUDED