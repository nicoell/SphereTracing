#ifndef STRUCTCUSTOMSAMPLEFUNCS_INCLUDED
#define STRUCTCUSTOMSAMPLEFUNCS_INCLUDED

#include "StructSampleFuncs.cginc"
#include "FilterUtils.cginc"

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
    SphereTracingData BilateralSampleSphereTracingData(uniform SamplerState smplr, in float2 uv, in float k, in float mipmap)
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
#endif
    
#ifdef AO_R

#endif

#endif // STRUCTCUSTOMSAMPLEFUNCS_INCLUDED