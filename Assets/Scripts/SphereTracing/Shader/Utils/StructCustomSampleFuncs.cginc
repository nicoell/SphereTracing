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

#endif

#endif // STRUCTCUSTOMSAMPLEFUNCS_INCLUDED