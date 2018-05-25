#ifndef DEFERREDLOGIC_INCLUDED
#define DEFERREDLOGIC_INCLUDED

#include "Defines/Structs.cginc"
#include "Inputs/DeferredRenderingInputs.cginc"

//#ifdef DEFERRED_CREATE || DEFERRED_PROCESS
    //bool ConsiderStep(in uint2 id, uniform int step) { return (step == 1 || id.x % step == 0 && id.y % step); }
    //uint2 GetScaledId(in uint2 id, uniform int step) { return id / step; }
    void EncodeFloat4InTexture2DArray(uniform RWTexture2DArray<float4> tex, in uint3 xyz, in float4 val)
    {
        tex[xyz] = val;
    }
    
    void EncodeFloatInTexture2DArray(uniform RWTexture2DArray<float> tex, in uint3 xyz, in float val)
    {
        tex[xyz] = val;
    }
    
    //bool ConsiderSurfaceData(uint2 id) { return ConsiderStep(id, SurfaceDataStep); }
    //bool ConsiderAmbientOcclusion(uint2 id) { return ConsiderStep(id, AmbientOcclusionStep); }
    //bool ConsiderDepth(uint2 id) { return ConsiderStep(id, DepthStep); }
    
    void EncodeSurfaceData(uniform RWTexture2DArray<float4> target, in uint2 xy, in uint k, in SurfaceData surface)
    {
        EncodeFloat4InTexture2DArray(target, uint3(xy, k*3 + 0), SurfaceDataStep, float4(surface.Position, surface.MaterialId));
        EncodeFloat4InTexture2DArray(target, uint3(xy, k*3 + 1), SurfaceDataStep, float4(surface.RayDirection, surface.TraceDistance));
        EncodeFloat4InTexture2DArray(target, uint3(xy, k*3 + 2), SurfaceDataStep, float4(surface.Normal, surface.Alpha));
    }
    
    void EncodeAmbientOcclusion(uniform RWTexture2DArray<float4> target, in uint2 xy, in uint k, in AmbientOcclusion surfaceAo)
    {
        EncodeFloat4InTexture2DArray(target, uint3(xy, k), AmbientOcclusionStep, float4(surfaceAo.BentNormal, surfaceAo.SpecularOcclusion));
    }
    
//#else 


void DecodeSurfaceData(uniform Texture2DArray<float4> target, in uint2 xy, in uint k, out SurfaceData surface)
{
    surface.Position = target[uint3(xy, k*3 + 0)].xyz;
    surface.MaterialId = (int) target[uint3(xy, k*3 + 0)].w;
    surface.RayDirection = target[uint3(xy, k*3 + 1)].xyz;
    surface.TraceDistance = target[uint3(xy, k*3 + 1)].w;
    surface.Normal = target[uint3(xy, k*3 + 2)].xyz;
    surface.Alpha = target[uint3(xy, k*3 + 2)].w;
}

void DecodeSurfaceData(uniform Texture2DArray<float4> target, in float2 uv, in uint k, in int mipmap, out SurfaceData surface)
{
    float4 pm = target.SampleLevel(float3(uv, k*3), mipmap);
    surface.Position = pm.xyz;
    surface.MaterialId = (int) pm.w;
    float4 rdtd = target.SampleLevel(float3(uv, k*3 + 1), mipmap);
    surface.RayDirection = rdtd.xyz;
    surface.TraceDistance = rdtd.w;
    float4 na = target.SampleLevel(float3(uv, k*3 + 2), mipmap);
    surface.Normal = na.xyz;
    surface.Alpha = na.w;
}

void DecodeRay(uniform Texture2DArray<float4> target, in uint2 xy, in uint k, inout Ray r)
{
    r.Origin = target[uint3(xy, k*3 + 0)].xyz;
    r.Direction = target[uint3(xy, k*3 + 1)].xyz;
}

float DecodeAlpha(uniform Texture2DArray<float4> target, in uint2 xy, in uint k)
{
    returntarget[uint3(xy, k*3 + 2)].w;
}

void DecodeAmbientOcclusion(uniform Texture2DArray<float4> target, in uint2 xy, in uint k, out AmbientOcclusion surfaceAo)
{
    surfaceAo.BentNormal = target[uint3(xy, k)].xyz;
    surfaceAo.SpecularOcclusion = target[uint3(xy, k)].w;
}

AmbientOcclusion LerpAO(AmbientOcclusion ao0, AmbientOcclusion ao1, float t)
{
    AmbientOcclusion ret;
    ret.BentNormal = lerp(ao0.BentNormal, ao1.BentNormal, t);
    ret.SpecularOcclusion = lerp(ao0.SpecularOcclusion, ao1.SpecularOcclusion, t);
    return ret;
}

//#endif



#endif // DEFERREDLOGIC_INCLUDED