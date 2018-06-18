#ifndef TEXTUREACCESSAWAREINPUTS_INCLUDED
#define TEXTUREACCESSAWAREINPUTS_INCLUDED

/* SphereTracingDataTexture
 *Holds two structs SphereTracingData for surface and represent:
 * Surface:
 * [0] Position.xyz, MaterialId
 * [1] RayDirection.xyz, TraceDistance
 * [2] Normal.xyz, Alpha
 * Represent(ative):
 * [3] Position.xyz, MaterialId
 * [4] RayDirection.xyz, TraceDistance
 * [5] Normal.xyz, Alpha
 */
#ifdef ST_RW
    //SphereTracing ReadWrite
    RWTexture2DArray<float4> SphereTracingDataTexture;
#elif ST_R
    //SphereTracing Read
    Texture2DArray<float4> SphereTracingDataTexture;
#endif

/* AmbientOcclusionTexture
 * Holds two structs AmbientOcclusion for surface and represent:
 * Surface:
 * [0] BentNormal.xyz, SpecularOcclusion
 * Represent(ative):
 * [1] BentNormal.xyz, SpecularOcclusion
 */
#ifdef AO_RW
    RWTexture2DArray<float4> AmbientOcclusionTexture;
#elif AO_R
    Texture2DArray<float4> AmbientOcclusionTexture;
#endif

/* DeferredOutputTexture
 * The texture the final image gets rendered into.
 * Surface:
 * [0] BentNormal.xyz, SpecularOcclusion
 * Represent(ative):
 * [1] BentNormal.xyz, SpecularOcclusion
 */
#ifdef DEF_RW
    RWTexture2D<float4> DeferredOutputTexture;
#endif

#endif // TEXTUREACCESSAWAREINPUTS_INCLUDED