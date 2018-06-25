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
 * SamplerState named smplr because unity prohibits naming it sampler
 */
 
#ifdef ST_R    
    SphereTracingData GatherSphereTracingDataMinMaxByDepth(uniform SamplerState smplr, in float2 uv, in float k, bool returnMax)
    {
        SphereTracingData surface;
        float4 posX = SphereTracingDataTexture.GatherRed(smplr, float3(uv, k*3.0));
        float4 posY = SphereTracingDataTexture.GatherGreen(smplr, float3(uv, k*3.0));
        float4 posZ = SphereTracingDataTexture.GatherBlue(smplr, float3(uv, k*3.0));
        float4 matId = SphereTracingDataTexture.GatherAlpha(smplr, float3(uv, k*3.0));
        
        float4 dirX = SphereTracingDataTexture.GatherRed(smplr, float3(uv, k*3.0 + 1.0));
        float4 dirY = SphereTracingDataTexture.GatherGreen(smplr, float3(uv, k*3.0 + 1.0));
        float4 dirZ = SphereTracingDataTexture.GatherBlue(smplr, float3(uv, k*3.0 + 1.0));
        float4 depth = SphereTracingDataTexture.GatherAlpha(smplr, float3(uv, k*3.0 + 1.0));
        
        float4 normalX = SphereTracingDataTexture.GatherRed(smplr, float3(uv, k*3.0 + 2.0));
        float4 normalY = SphereTracingDataTexture.GatherGreen(smplr, float3(uv, k*3.0 + 2.0));
        float4 normalZ = SphereTracingDataTexture.GatherBlue(smplr, float3(uv, k*3.0 + 2.0));
        float4 alpha = SphereTracingDataTexture.GatherAlpha(smplr, float3(uv, k*3.0 + 2.0));
        
        int i;
        if (returnMax)
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
        return surface;
}
    
    SphereTracingData DownsampleSphereTracingData(in float2 uvCenterLow, in float2 uvStepFull, in float k, in float mipmapLevel)
    {
        float gatherOffset = -1 + pow(2.0, mipmapLevel - 1);    // 1->0, 2->1, 3->3, 4->7 , ...
        float gatherCount = -1 + pow(2.0, mipmapLevel);         // 1->1, 2->3, 3->7, 4->15, ...
        float2 topLeft = uvCenterLow - gatherOffset * uvStepFull;
        bool returnMax = CheckerBoard(uvCenterLow, AoResolution);
        
        SphereTracingData stRet = GatherSphereTracingDataMinMaxByDepth(sampler_point_clamp, uvCenterLow, k, returnMax);
        
        if (returnMax){
            for(int y = 0; y < gatherCount; y++){
                for(int x = 0; x < gatherCount; x++){
                    if (y == x && x == gatherOffset) continue; //Skip second uvCenterLow
                    float2 currentUv = topLeft + float2(x * uvStepFull.x, y * uvStepFull.y);
                    SphereTracingData stTap = GatherSphereTracingDataMinMaxByDepth(sampler_point_clamp, currentUv, k, true);
                    if (stTap.TraceDistance > stRet.TraceDistance) stRet = stTap;
                }
            }
        } else {
            for(int y = 0; y < gatherCount; y++){
                for(int x = 0; x < gatherCount; x++){
                    if (y == x && x == gatherOffset) continue; //Skip second uvCenterLow
                    float2 currentUv = topLeft + float2(x * uvStepFull.x, y * uvStepFull.y);
                    SphereTracingData stTap = GatherSphereTracingDataMinMaxByDepth(sampler_point_clamp, currentUv, k, false);
                    if (stTap.TraceDistance < stRet.TraceDistance) stRet = stTap;
                }
            }
        }
        
        return stRet;
    } 
     
#endif
    
#ifdef AO_R
    AmbientOcclusion UpSampleAmbientOcclusion(in float2 uv, in float k, in float mipmap)
    {
        //Gather 4 Ao Samples from ao texture created in lowres
        float4 aoX = AmbientOcclusionTexture.GatherRed(sampler_linear_clamp, float3(uv, k));
        float4 aoY = AmbientOcclusionTexture.GatherGreen(sampler_linear_clamp, float3(uv, k));
        float4 aoZ = AmbientOcclusionTexture.GatherBlue(sampler_linear_clamp, float3(uv, k));
        float4 aoW = AmbientOcclusionTexture.GatherAlpha(sampler_linear_clamp, float3(uv, k));

        //stitch them back together
        float4 aoLow[4] = {
            float4(aoX.x, aoY.x, aoZ.x, aoW.x),
            float4(aoX.y, aoY.y, aoZ.y, aoW.y),
            float4(aoX.z, aoY.z, aoZ.z, aoW.z),
            float4(aoX.w, aoY.w, aoZ.w, aoW.w)
        };

        //Gather 4 depth and normal samples from downsampled spheretracingdata texture
        float4 depth = SphereTracingDataTextureLow.GatherAlpha(sampler_linear_clamp, float3(uv, k*3.0 + 1.0));
        float4 normalX = SphereTracingDataTextureLow.GatherRed(sampler_linear_clamp, float3(uv, k*3.0 + 2.0));
        float4 normalY = SphereTracingDataTextureLow.GatherGreen(sampler_linear_clamp, float3(uv, k*3.0 + 2.0));
        float4 normalZ = SphereTracingDataTextureLow.GatherBlue(sampler_linear_clamp, float3(uv, k*3.0 + 2.0));
        //stitch them back together
        float depthLow[4] = {
            depth.x,
            depth.y,
            depth.z,
            depth.w
        };
        float3 normalLow[4] = {
            float3(normalX.x, normalY.x, normalZ.x),
            float3(normalX.y, normalY.y, normalZ.y),
            float3(normalX.z, normalY.z, normalZ.z),
            float3(normalX.w, normalY.w, normalZ.w)
        };

        //Sample normal and depth from fullres texture
        float3 normalFull = SampleNormal(sampler_point_clamp, uv, k, mipmap);
        float depthFull = SampleTraceDistance(sampler_point_clamp, uv, k, mipmap);

        const float epsilon = 0.001;
        float totalWeight = 0;
        float4 aoUpsampled = (float4) 0.0;

        for(int i = 0; i<4; i++)
        {
            float depthDiff = abs(depthFull - depthLow[i]);
            float depthWeight = 1.0 / (epsilon + depthDiff);

            float normalWeight = pow(dot(normalFull, normalLow[i]), 32);

            float combinedWeight = depthWeight * normalWeight;
            totalWeight += combinedWeight;

            aoUpsampled += aoLow[i] * combinedWeight;
        }

        aoUpsampled /= totalWeight;

        AmbientOcclusion aoRet;
        aoRet.BentNormal = aoUpsampled.xyz;
        aoRet.SpecularOcclusion = aoUpsampled.w;
        return aoRet;
    }

#endif

#endif // STRUCTCUSTOMSAMPLEFUNCS_INCLUDED