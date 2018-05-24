#ifndef DEFERREDLOGIC_INCLUDED
#define DEFERREDLOGIC_INCLUDED

#include "Defines/Structs.cginc"
#include "Inputs/DeferredRenderingInputs.cginc"

//#ifdef DEFERRED_CREATE || DEFERRED_PROCESS
    bool ConsiderStep(in uint2 id, uniform int step) { return (step == 1 || id.x % step == 0 && id.y % step); }
    uint2 GetScaledId(in uint2 id, uniform int step) { return id / step; }
    void EncodeFloat4InTexture2DArray(uniform RWTexture2DArray<float4> tex, in uint3 xyz, uniform int step, in float4 val)
    {
        tex[uint3(GetScaledId(xyz.xy, step), xyz.z)] = val;
    }
    void EncodeUnscaledFloat4InTexture2DArray(uniform RWTexture2DArray<float4> tex, in uint3 xyz, uniform int step, in float4 val)
    {
        tex[xyz] = val;
    }
    void EncodeFloatInTexture2DArray(uniform RWTexture2DArray<float> tex, in uint3 xyz, uniform int step, in float val)
    {
        tex[uint3(GetScaledId(xyz.xy, step), xyz.z)] = val;
    }
    
    bool ConsiderSurfaceData(uint2 id) { return ConsiderStep(id, SurfaceDataStep); }
    bool ConsiderAmbientOcclusion(uint2 id) { return ConsiderStep(id, AmbientOcclusionStep); }
    bool ConsiderDepth(uint2 id) { return ConsiderStep(id, DepthStep); }
    
    void EncodeSurfaceData(uniform RWTexture2DArray<float4> target, in uint2 xy, in uint k, in SurfaceData surface, in SurfaceData represent)
    {
        EncodeFloat4InTexture2DArray(target, uint3(xy, k*4 + 0), SurfaceDataStep, float4(surface.Position, surface.MaterialId));
        EncodeFloat4InTexture2DArray(target, uint3(xy, k*4 + 1), SurfaceDataStep, float4(surface.Normal, surface.Alpha));
        EncodeFloat4InTexture2DArray(target, uint3(xy, k*4 + 2), SurfaceDataStep, float4(represent.Position, represent.MaterialId));
        EncodeFloat4InTexture2DArray(target, uint3(xy, k*4 + 3), SurfaceDataStep, float4(represent.Normal, represent.Alpha));
    }
    
    void EncodeAmbientOcclusion(uniform RWTexture2DArray<float4> target, in uint2 xy, in uint k, in AmbientOcclusion surfaceAo, in AmbientOcclusion representativeAo)
    {
        EncodeFloat4InTexture2DArray(target, uint3(xy, k*2 + 0), AmbientOcclusionStep, float4(surfaceAo.BentNormal, surfaceAo.SpecularOcclusion));
        EncodeFloat4InTexture2DArray(target, uint3(xy, k*2 + 1), AmbientOcclusionStep, float4(representativeAo.BentNormal, representativeAo.SpecularOcclusion));
    }
    
    void EncodeUnscaledAmbientOcclusion(uniform RWTexture2DArray<float4> target, in uint2 xy, in uint k, in AmbientOcclusion surfaceAo, in AmbientOcclusion representativeAo)
    {
        EncodeUnscaledFloat4InTexture2DArray(target, uint3(xy, k*2 + 0), AmbientOcclusionStep, float4(surfaceAo.BentNormal, surfaceAo.SpecularOcclusion));
        EncodeUnscaledFloat4InTexture2DArray(target, uint3(xy, k*2 + 1), AmbientOcclusionStep, float4(representativeAo.BentNormal, representativeAo.SpecularOcclusion));
    }
    
    void EncodeDepth(uniform RWTexture2DArray<float> target, in uint2 xy, in uint k, in float surfaceDepth, in float representativeDepth)
    {
        EncodeFloatInTexture2DArray(target, uint3(xy, k*2 + 0), DepthStep, surfaceDepth);
        EncodeFloatInTexture2DArray(target, uint3(xy, k*2 + 1), DepthStep, representativeDepth);
    }
    
//#else 


void DecodeSurfaceData(uniform Texture2DArray<float4> target, in uint2 xy, in uint k, out SurfaceData surface, out SurfaceData represent)
{
    surface.Position = target[uint3(xy, k*4 + 0)].xyz;
    surface.MaterialId = (int) target[uint3(xy, k*4 + 0)].w;
    surface.Normal = target[uint3(xy, k*4 + 1)].xyz;
    surface.Alpha = target[uint3(xy, k*4 + 1)].w;
    represent.Position = target[uint3(xy, k*4 + 2)].xyz;
    represent.MaterialId = (int) target[uint3(xy, k*4 + 2)].w;
    represent.Normal = target[uint3(xy, k*4 + 3)].xyz;
    represent.Alpha = target[uint3(xy, k*4 + 3)].w;
}
void DecodeAmbientOcclusion(uniform Texture2DArray<float4> target, in uint2 xy, in uint k, out AmbientOcclusion surfaceAo, out AmbientOcclusion representativeAo)
{
    surfaceAo.BentNormal = target[uint3(xy, k*2 + 0)].xyz;
    surfaceAo.SpecularOcclusion = target[uint3(xy, k*2 + 0)].w;
    representativeAo.BentNormal = target[uint3(xy, k*2 + 1)].xyz;
    representativeAo.SpecularOcclusion = target[uint3(xy, k*2 + 1)].w;
}
void DecodeDepth(uniform Texture2DArray<float> target, in uint2 xy, in uint k, out float surfaceDepth, out float representativeDepth)
{
    surfaceDepth = target[uint3(xy, k*2 + 0)];
    representativeDepth = target[uint3(xy, k*2 + 1)];
}

AmbientOcclusion LerpAO(AmbientOcclusion ao0, AmbientOcclusion ao1, float t)
{
    AmbientOcclusion ret;
    ret.BentNormal = lerp(ao0.BentNormal, ao1.BentNormal, t);
    ret.SpecularOcclusion = lerp(ao0.SpecularOcclusion, ao1.SpecularOcclusion, t);
    //ret.BentNormal = float3(t,1,t);
    //ret.SpecularOcclusion = 1;
    return ret;
}

//#endif



#endif // DEFERREDLOGIC_INCLUDED