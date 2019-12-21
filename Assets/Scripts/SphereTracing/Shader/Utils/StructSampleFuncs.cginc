#ifndef STRUCTSAMPLEFUNCS_INCLUDED
#define STRUCTSAMPLEFUNCS_INCLUDED

#include "Defines/Structs.cginc"
#include "Inputs/TextureAccessAwareInputs.cginc"

/*
 * Create SamplerStates for texture sampling
 */
SamplerState sampler_point_clamp;
SamplerState sampler_linear_clamp;

/*
 * Description of parameters:
 * float2 uv:    UV coordinates to sample a texture.
 * float k:      The k-layer to index the coordinate texturearray depth, 0 for surface, 1 for represent.
 */

/*
 * Sample functions using texture sampling to ease reading interpolated or mipmapped values of textures.
 * - Only define functions if corresponing (R)ead defines are set.
 * samplerState named smplr because unity prohibits naming it sampler
 */
 
#ifdef ST_R
    SphereTracingData SampleSphereTracingData(uniform SamplerState smplr, in float2 uv, in float k, in float mipmap)
    {
        SphereTracingData stData;
        float4 pm = SphereTracingDataTexture.SampleLevel(smplr, float3(uv, k*3.0), mipmap);
        stData.Position = pm.xyz;
        stData.MaterialId = (int) pm.w;
        float4 rdtd = SphereTracingDataTexture.SampleLevel(smplr, float3(uv, k*3.0 + 1.0), mipmap);
        stData.RayDirection = rdtd.xyz;
        stData.TraceDistance = rdtd.w;
        float4 na = SphereTracingDataTexture.SampleLevel(smplr, float3(uv, k*3.0 + 2.0), mipmap);
        stData.Normal = na.xyz;
        stData.Alpha = na.w;
        return stData;
    }
    
    float SampleTraceDistance(uniform SamplerState smplr, in float2 uv, in float k, in float mipmap)
    {
        return SphereTracingDataTexture.SampleLevel(smplr, float3(uv, k*3.0 + 1.0), mipmap).w;
    }

    float3 SampleNormal(uniform SamplerState smplr, in float2 uv, in float k, in float mipmap)
    {
        return SphereTracingDataTexture.SampleLevel(smplr, float3(uv, k*3.0 + 2.0), mipmap).xyz;
    }
#endif
    
#ifdef AO_R
    AmbientOcclusion SampleAmbientOcclusion(uniform SamplerState smplr, in float2 uv, in float k, in float mipmap)
    {
        AmbientOcclusion ret;
        float4 ao = AmbientOcclusionTexture.SampleLevel(smplr, float3(uv, k), mipmap);
        ret.BentNormal = ao.xyz;
        ret.SpecularOcclusion = ao.w;
        return ret;
    }
    
    float4 SampleAmbientOcclusionAsFloat4(uniform SamplerState smplr, in float2 uv, in float k, in float mipmap)
    {
        return AmbientOcclusionTexture.SampleLevel(smplr, float3(uv, k), mipmap);
    }
#endif

#endif // STRUCTSAMPLEFUNCS_INCLUDED