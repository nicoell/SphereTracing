#ifndef DEFERREDLOGIC_INCLUDED
#define DEFERREDLOGIC_INCLUDED

#include "Defines/Structs.cginc"
#include "Inputs/DeferredRenderingInputs.cginc"
#include "Utils/Filtering.cginc"

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
    void SampleSphereTracingData(in float2 uv, in float k, out SphereTracingData surface)
    {
        float4 pm = SphereTracingDataTexture.SampleLevel(sampler_linear_clamp, float3(uv, k*3.0), 0.0);
        surface.Position = pm.xyz;
        surface.MaterialId = (int) pm.w;
        float4 rdtd = SphereTracingDataTexture.SampleLevel(sampler_linear_clamp, float3(uv, k*3.0 + 1.0), 0.0);
        surface.RayDirection = rdtd.xyz;
        surface.TraceDistance = rdtd.w;
        float4 na = SphereTracingDataTexture.SampleLevel(sampler_linear_clamp, float3(uv, k*3.0 + 2.0), 0.0);
        surface.Normal = na.xyz;
        surface.Alpha = na.w;
    }

    void DecodeSphereTracingDataCheckerBoard(in float2 uv, in float k, out SphereTracingData surface)
    {
        float4 posX = SphereTracingDataTexture.GatherRed(sampler_point_clamp, float3(uv, k*3.0));
        float4 posY = SphereTracingDataTexture.GatherGreen(sampler_point_clamp, float3(uv, k*3.0));
        float4 posZ = SphereTracingDataTexture.GatherBlue(sampler_point_clamp, float3(uv, k*3.0));
        float4 matId = SphereTracingDataTexture.GatherAlpha(sampler_point_clamp, float3(uv, k*3.0));
        
        float4 dirX = SphereTracingDataTexture.GatherRed(sampler_point_clamp, float3(uv, k*3.0 + 1.0));
        float4 dirY = SphereTracingDataTexture.GatherGreen(sampler_point_clamp, float3(uv, k*3.0 + 1.0));
        float4 dirZ = SphereTracingDataTexture.GatherBlue(sampler_point_clamp, float3(uv, k*3.0 + 1.0));
        float4 depth = SphereTracingDataTexture.GatherAlpha(sampler_point_clamp, float3(uv, k*3.0 + 1.0));
        
        float4 normalX = SphereTracingDataTexture.GatherRed(sampler_point_clamp, float3(uv, k*3.0 + 2.0));
        float4 normalY = SphereTracingDataTexture.GatherGreen(sampler_point_clamp, float3(uv, k*3.0 + 2.0));
        float4 normalZ = SphereTracingDataTexture.GatherBlue(sampler_point_clamp, float3(uv, k*3.0 + 2.0));
        float4 alpha = SphereTracingDataTexture.GatherAlpha(sampler_point_clamp, float3(uv, k*3.0 + 2.0));
        
        int i;
        
        if (CheckerBoard(uv, AoResolution))
        {
            i = IndexOfMaxComponent(depth);
        } else {
            i = IndexOfMinComponent(depth);
        }
        surface.Position = float3(posX[i], posY[i], posZ[i]);
        surface.MaterialId = (int) matId[i];
        surface.RayDirection = float3(dirX[i], dirY[i], dirZ[i]);
        surface.TraceDistance = depth[i];
        surface.Normal = float3(normalX[i], normalY[i], normalZ[i]);
        surface.Alpha = alpha[i];
    }
    
    float DecodeTraceDistance(in float2 uv, in float k)
    {
        return SphereTracingDataTexture.SampleLevel(sampler_linear_clamp, float3(uv, k*3.0 + 1.0), 0.0).w;
    }
    
    float DecodeTraceDistanceCheckerBoard(in float2 uv, in float k)
    {
        float4 depth = SphereTracingDataTexture.GatherAlpha(sampler_linear_clamp, float3(uv, k*3.0 + 1.0));
        
        if (CheckerBoard(uv, AoResolution))
        {
            return max4(depth.x, depth.y, depth.z, depth.w);
        } else {
            return min4(depth.x, depth.y, depth.z, depth.w);
        }
    }
    
    float3 DecodeNormal(in float2 uv, in float k)
    {
        return SphereTracingDataTexture.SampleLevel(sampler_linear_clamp, float3(uv, k*3.0 + 2.0), 0.0).xyz;
    }
    
    float3 DecodeNormalCheckerBoard(in float2 uv, in float k)
    {
        float4 depth = SphereTracingDataTexture.GatherAlpha(sampler_linear_clamp, float3(uv, k*3.0 + 1.0));
        float4 normalX = SphereTracingDataTexture.GatherRed(sampler_linear_clamp, float3(uv, k*3.0 + 2.0));
        float4 normalY = SphereTracingDataTexture.GatherGreen(sampler_linear_clamp, float3(uv, k*3.0 + 2.0));
        float4 normalZ = SphereTracingDataTexture.GatherBlue(sampler_linear_clamp, float3(uv, k*3.0 + 2.0));
        
        int i;
        
        if (CheckerBoard(uv, AoResolution))
        {
            i = IndexOfMaxComponent(depth);
        } else {
            i = IndexOfMinComponent(depth);
        }
        return float3(normalX[i], normalY[i], normalZ[i]);
    }
    #endif
    
    #ifdef AO_R
    #include "AmbientOcclusion.cginc"
    AmbientOcclusion DecodeAmbientOcclusion(in float2 uv, in float k)
    {
        float4 ao = AmbientOcclusionTexture.SampleLevel(sampler_linear_clamp, float3(uv, k), 0.0);
        AmbientOcclusion ret;
        ret.BentNormal = ao.xyz;
        ret.SpecularOcclusion = ao.w;
        return ret;
    }
    
    AmbientOcclusion DecodeAmbientOcclusionCheckerBoard(in float2 uv, in float k)
    {
        float4 aoX = AmbientOcclusionTexture.GatherRed(sampler_point_clamp, float3(uv, k), 0.0);
        float4 aoY = AmbientOcclusionTexture.GatherGreen(sampler_point_clamp, float3(uv, k), 0.0);
        float4 aoZ = AmbientOcclusionTexture.GatherBlue(sampler_point_clamp, float3(uv, k), 0.0);
        float4 aoW = AmbientOcclusionTexture.GatherAlpha(sampler_point_clamp, float3(uv, k), 0.0);
        
        float4 BentNormalLength = float4(
        length(float4(aoX.x, aoY.x, aoZ.x, aoW.x)), 
        length(float4(aoX.y, aoY.y, aoZ.y, aoW.y)), 
        length(float4(aoX.z, aoY.z, aoZ.z, aoW.z)), 
        length(float4(aoX.w, aoY.w, aoZ.w, aoW.w)));
        
        //float4 ao = AmbientOcclusionTexture.SampleLevel(sampler_linear_clamp, float3(uv, k), 0.0);
        int i;
        
        if (CheckerBoard(uv, AoResolution))
        {
            i = IndexOfMaxComponent(BentNormalLength);
        } else {
            i = IndexOfMinComponent(BentNormalLength);
        }
        float4 ao = float4(aoX[i], aoY[i], aoZ[i], aoW[i]);
        
        AmbientOcclusion ret;
        ret.BentNormal = ao.xyz;
        ret.SpecularOcclusion = ao.w;
        return ret;
    }
    
    float NearestDepthThreshold;

    AmbientOcclusion DecodeAmbientOcclusionBilateralUpsampled(in float2 uv, in float k)
    {
        float2 uvStepAo = float2(1.0 / AoResolution.x, 1.0 / AoResolution.y);
        float2 uv00 = uv - 0.5 * uvStepAo;
        float2 uv10 = uv00 + float2(uvStepAo.x, 0.0);
        float2 uv01 = uv00 + float2(0.0, uvStepAo.y);
        float2 uv11 = uv00 + uvStepAo;
        
        float depthFull = DecodeTraceDistance(uv, k);
        float d00 = DecodeTraceDistanceCheckerBoard(uv00, k);
        float d10 = DecodeTraceDistanceCheckerBoard(uv10, k);
        float d01 = DecodeTraceDistanceCheckerBoard(uv01, k);
        float d11 = DecodeTraceDistanceCheckerBoard(uv11, k);
        float4 dSamples = float4(d00, d10, d01, d11);        
        
        float4 depthDelta = abs(dSamples - depthFull);
        float tolerance = (depthFull / ClippingPlanes.y) * NearestDepthThreshold;
        float planeAngle = PI / 4.0 * NearestDepthThreshold;
        float slopeThreshold = (depthFull / ClippingPlanes.y) * 2 * 
            ( ( ( cos(AngleBetweenRays.x) * sin(planeAngle) ) / (sin(planeAngle - AngleBetweenRays.x) ) ) - 1);
        float4 depthWeights = 1.0 / (0.0001 + depthDelta * slopeThreshold);
        
        float3 normalFull = DecodeNormal(uv, k);
        float3 n00 = DecodeNormalCheckerBoard(uv00, k);
        float3 n10 = DecodeNormalCheckerBoard(uv10, k);
        float3 n01 = DecodeNormalCheckerBoard(uv01, k);
        float3 n11 = DecodeNormalCheckerBoard(uv11, k);    
        
        float4 normalWeights;
        normalWeights.x = 1 - abs(dot(n00, normalFull));
        normalWeights.y = 1 - abs(dot(n10, normalFull));
        normalWeights.z = 1 - abs(dot(n01, normalFull));
        normalWeights.w = 1 - abs(dot(n11, normalFull));
        
        AmbientOcclusion ret;
        float4 ao;
        
        float4 totalWeights = depthWeights;
        /*
        if (min4(normalWeights) >= NearestDepthThreshold)
        {
            float4 ao;
            ao = AmbientOcclusionTexture.SampleLevel(sampler_point_clamp, float3(uv, k), 0.0);
            ret.BentNormal = ao.xyz;
            ret.SpecularOcclusion = ao.w;
        } else {
            ao = AmbientOcclusionTexture.SampleLevel(sampler_linear_clamp, float3(uv, k), 0.0);
            ret.BentNormal = ao.xyz;
            ret.SpecularOcclusion = ao.w;
        }
        */
        if (totalWeights.x < NearestDepthThreshold && totalWeights.y < NearestDepthThreshold &&
            totalWeights.z < NearestDepthThreshold && totalWeights.w < NearestDepthThreshold)
        {
            ao = AmbientOcclusionTexture.SampleLevel(sampler_linear_clamp, float3(uv, k), 0.0);
        } else {
            //int i = IndexOfMinComponent(depthDelta
            ao = float4(0, 0, 0, 0);
        }
        
        ret.BentNormal = depthWeights.xyz;
        ret.SpecularOcclusion = slopeThreshold;
        return ret;
        
        /*
        
        float4 ao00 = AmbientOcclusionTexture.SampleLevel(sampler_point_clamp, float3(uv00, k), 0.0);
        float4 ao10 = AmbientOcclusionTexture.SampleLevel(sampler_point_clamp, float3(uv10, k), 0.0);
        float4 ao01 = AmbientOcclusionTexture.SampleLevel(sampler_point_clamp, float3(uv01, k), 0.0);
        float4 ao11 = AmbientOcclusionTexture.SampleLevel(sampler_point_clamp, float3(uv11, k), 0.0);
        
        float4 aoWeighted = ao00 * totalWeights.x + ao01 * totalWeights.y + ao10 * totalWeights.z + ao11 * totalWeights.w;
        aoWeighted /= totalWeights.x + totalWeights.y + totalWeights.z + totalWeights.w;
        
        ret.BentNormal = aoWeighted.xyz;
        ret.SpecularOcclusion = aoWeighted.w;
        return ret;*/
    }
    
    AmbientOcclusion DecodeAmbientOcclusionNearestDepth(in float2 uv, in float k)
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
        
        //TODO: use gather
        
        float d00 = DecodeTraceDistanceCheckerBoard(uv00, k);
        float d10 = DecodeTraceDistanceCheckerBoard(uv10, k);
        float d01 = DecodeTraceDistanceCheckerBoard(uv01, k);
        float d11 = DecodeTraceDistanceCheckerBoard(uv11, k);
        
        float dfull = DecodeTraceDistance(uv, k);
        
        float delta00 = abs(d00 - dfull);
        float delta10 = abs(d10 - dfull);
        float delta01 = abs(d01 - dfull);
        float delta11 = abs(d11 - dfull);
        
        float4 ao;
        
        if (delta00 < NearestDepthThreshold && delta10 < NearestDepthThreshold &&
            delta01 < NearestDepthThreshold && delta11 < NearestDepthThreshold)
        {
            ao = AmbientOcclusionTexture.SampleLevel(sampler_linear_clamp, float3(uv, k), 0.0);
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
            ao = AmbientOcclusionTexture.SampleLevel(sampler_point_clamp, float3(uvmin, k), 0.0);
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