#ifndef DEFERREDLOGIC_INCLUDED
#define DEFERREDLOGIC_INCLUDED

#include "Defines/Structs.cginc"
#include "Inputs/DeferredRenderingInputs.cginc"

/*
 * Encode functions to ease write of data in textures.
 * - Only define functions if corresponing (R)ead(W)rite define is set. 
 */

    #ifdef ST_RW
    void EncodeSphereTracingData(in uint2 xy, in uint k, in SphereTracingData surface)
    {
        SphereTracingDataTexture[uint3(xy, k*3 + 0)] = float4(surface.Position, surface.MaterialId);
        SphereTracingDataTexture[uint3(xy, k*3 + 1)] = float4(surface.RayDirection, surface.TraceDistance);
        SphereTracingDataTexture[uint3(xy, k*3 + 2)] = float4(surface.Normal, surface.Alpha);
    }
    #endif
    
    #ifdef AO_RW
    void EncodeAmbientOcclusion(in uint2 xy, in uint k, in AmbientOcclusion surfaceAo)
    {
        AmbientOcclusionTexture[uint3(xy, k)] = float4(surfaceAo.BentNormal, surfaceAo.SpecularOcclusion);
    }
    #endif

/*
 * Decode functions to ease reading of texture data.
 * - Only define functions if corresponing (R)ead or (R)ead(W)rite defines are set.
 */

    #if defined(ST_R) || defined(ST_RW)
    void DecodeSphereTracingData(in uint2 xy, in uint k, out SphereTracingData surface)
    {
        surface.Position = SphereTracingDataTexture[uint3(xy, k*3 + 0)].xyz;
        surface.MaterialId = (int) SphereTracingDataTexture[uint3(xy, k*3 + 0)].w;
        surface.RayDirection = SphereTracingDataTexture[uint3(xy, k*3 + 1)].xyz;
        surface.TraceDistance = SphereTracingDataTexture[uint3(xy, k*3 + 1)].w;
        surface.Normal = SphereTracingDataTexture[uint3(xy, k*3 + 2)].xyz;
        surface.Alpha = SphereTracingDataTexture[uint3(xy, k*3 + 2)].w;
    }
    
    void DecodeRay(in uint2 xy, in uint k, inout Ray r)
    {
        r.Origin = SphereTracingDataTexture[uint3(xy, k*3 + 0)].xyz;
        r.Direction = SphereTracingDataTexture[uint3(xy, k*3 + 1)].xyz;
    }
    
    float DecodeAlpha(in uint2 xy, in uint k)
    {
        return SphereTracingDataTexture[uint3(xy, k*3 + 2)].w;
    }
    #endif
    
    #if defined(AO_R) || defined(AO_RW)
    void DecodeAmbientOcclusion(in uint2 xy, in uint k, out AmbientOcclusion surfaceAo)
    {
        surfaceAo.BentNormal = AmbientOcclusionTexture[uint3(xy, k)].xyz;
        surfaceAo.SpecularOcclusion = AmbientOcclusionTexture[uint3(xy, k)].w;
    }
    #endif

/*
 * Decode functions using texture sampling to ease reading interpolated or mipmapped values of textures.
 * - Only define functions if corresponing (R)ead defines are set.
 */

    #ifdef ST_R
    void DecodeSphereTracingData(in float2 uv, in float k, in float mipmap, out SphereTracingData surface)
    {
        float4 pm = SphereTracingDataTexture.SampleLevel(sampler_linear_clamp, float3(uv, k*3.0), mipmap);
        surface.Position = pm.xyz;
        surface.MaterialId = (int) pm.w;
        float4 rdtd = SphereTracingDataTexture.SampleLevel(sampler_linear_clamp, float3(uv, k*3.0 + 1.0), mipmap);
        surface.RayDirection = rdtd.xyz;
        surface.TraceDistance = rdtd.w;
        float4 na = SphereTracingDataTexture.SampleLevel(sampler_linear_clamp, float3(uv, k*3.0 + 2.0), mipmap);
        surface.Normal = na.xyz;
        surface.Alpha = na.w;
    }
    float DecodeTraceDistance(in float2 uv, in float k, in float mipmap)
    {
        return SphereTracingDataTexture.SampleLevel(sampler_linear_clamp, float3(uv, k*3.0 + 1.0), mipmap).w;
    }
    #endif
    
#ifdef AO_R
    AmbientOcclusion DecodeAmbientOcclusion(in float2 uv, in float k, in float mipmap)
    {
        float4 ao = AmbientOcclusionTexture.SampleLevel(sampler_point_clamp, float3(uv, k), mipmap);
        AmbientOcclusion ret;
        ret.BentNormal = ao.xyz;
        ret.SpecularOcclusion = ao.w;
        return ret;
    }
    
    float NearestDepthThreshold;
    
    AmbientOcclusion DecodeAmbientOcclusionNearestDepth(in float2 uv, in float k, in float mipmap)
    {
        // Implements Nearest Depth Upsampling 
        // http://developer.download.nvidia.com/assets/gamedev/files/sdk/11/OpacityMappingSDKWhitePaper.pdf
        
        const float depthThres = 2;
        float2 dir = float2(1, 0);
        float2 uvStepAo = float2(1.0 / AoResolution.x, 1.0 / AoResolution.y);
        
        float2 uv00 = uv - 0.5 * uvStepAo;
        float2 uv10 = uv00 + float2(uvStepAo.x, 0.0);
        float2 uv01 = uv00 + float2(0.0, uvStepAo.y);
        float2 uv11 = uv00 + uvStepAo;
        
        float d00 = DecodeTraceDistance(uv00, k, AoTargetMip);
        float d10 = DecodeTraceDistance(uv10, k, AoTargetMip);
        float d01 = DecodeTraceDistance(uv01, k, AoTargetMip);
        float d11 = DecodeTraceDistance(uv11, k, AoTargetMip);
        
        float dfull = DecodeTraceDistance(uv, k, 0.0);
        
        float delta00 = abs(d00 - dfull);
        float delta10 = abs(d10 - dfull);
        float delta01 = abs(d01 - dfull);
        float delta11 = abs(d11 - dfull);
        
        float4 ao;
        
        if (delta00 < NearestDepthThreshold && delta10 < NearestDepthThreshold &&
            delta01 < NearestDepthThreshold && delta11 < NearestDepthThreshold)
        {
            ao = AmbientOcclusionTexture.SampleLevel(sampler_linear_clamp, float3(uv, k), mipmap);
        } else 
        {
            float2 uvmin = uv;
            float deltaMin = 9999999.0;
            if (delta00 < deltaMin) {
                deltaMin = delta00;
                uvmin = uv00;
            }
            if (delta01 < deltaMin) {
                deltaMin = delta01;
                uvmin = uv01;
            }
            if (delta10 < deltaMin) {
                deltaMin = delta10;
                uvmin = uv10;
            }
            if (delta11 < deltaMin) {
                deltaMin = delta11;
                uvmin = uv11;
            }
            ao = AmbientOcclusionTexture.SampleLevel(sampler_point_clamp, float3(uvmin, k), mipmap);
        }
        AmbientOcclusion ret;
        ret.BentNormal = ao.xyz;
        ret.SpecularOcclusion = ao.w;
        return ret;
    }

#endif

AmbientOcclusion LerpAO(AmbientOcclusion ao0, AmbientOcclusion ao1, float t)
{
    AmbientOcclusion ret;
    ret.BentNormal = lerp(ao0.BentNormal, ao1.BentNormal, t);
    ret.SpecularOcclusion = lerp(ao0.SpecularOcclusion, ao1.SpecularOcclusion, t);
    return ret;
}


#endif // DEFERREDLOGIC_INCLUDED