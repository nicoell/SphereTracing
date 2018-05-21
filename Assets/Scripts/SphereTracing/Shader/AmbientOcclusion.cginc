#ifndef AMBIENTOCCLUSION_INCLUDED
#define AMBIENTOCCLUSION_INCLUDED

#include "UniformVariables.cginc"       //Contains the resources set from CPU.
#include "ImplicitBasics.cginc"
#include "StructDefinitions.cginc"
#include "WorldLogic.cginc"
#include "Random.cginc"

float3 SphericalFibonacciMapping(float i, float n, float rand)
{
    float phi = i * 2.0 * PI * GOLDENRATIO + rand;
    float zi = 1.0 - (2.0*i+1.0)/(n);
    float theta = sqrt(1.0 - zi*zi);
    return float3( cos(phi) * theta, sin(phi) * theta, zi);
}

float3 HemisphericalFibonacciMapping(float i, float n, float rand)
{
    float phi = i * 2.0 * PI * GOLDENRATIO + rand;
    float zi = 1.0 - (2.0*i+1.0)/(2*n);
    float theta = sqrt(1.0 - zi*zi);
    return normalize(float3( cos(phi) * theta, sin(phi) * theta, zi));
}

float3 UniformSampleHemisphere(float r1, float r2)
{
    float cosTheta = 2.0 * r1 - 1.0;
    float sinTheta = sqrt(1.0 - r1 * r1);
    float phi = 2 * PI * r2;
    return float3(sinTheta * cos(phi), sinTheta * sin(phi), cosTheta);
} 


void GetCoordinateSystem(in float3 normal, out float3 tangent, out float3 bitangent)
{
    float3 up = abs(normal.y) < 0.999 ? float3(0, 1, 0) : float3(1,0,0);
    tangent = normalize( cross( up, normal ) );
    bitangent = cross( normal, tangent );   
}

float ApproxConeConeIntersection(float arcLength1, float arcLength2, float angleBetweenCones)
{
    float angleDiff = abs(arcLength1 - arcLength2);
    
    return smoothstep(0, 1,
     1.0 - saturate((angleBetweenCones - angleDiff) / (arcLength1 + arcLength2 - angleDiff)));
}

float GetConeVisibility(in Ray coneRay, in float tanConeAngle)
{
    float minSphereRadius = 0.04; //TODO: Causes artefacts if not small enough
    float maxSphereRadius = 100.0;

    float minVisibility = 1.0;
    float minDistance = 1000000;
    float traceDistance = 0.1;
    float minStepSize = 0;//1.0 / (4.0 * AmbientOcclusionSteps); //TODO: Also causes artefacts
    
    for(int step = 0; step < AmbientOcclusionSteps; step++)
    {
        float epsilon = 0.00015 * traceDistance;
        float3 pointOnRay = coneRay.Origin + traceDistance * coneRay.Direction;
        float distance = Map(pointOnRay).x;
        
        minDistance = min(minDistance, distance);
        float sphereRadius = clamp(tanConeAngle * traceDistance, minSphereRadius, maxSphereRadius);
        
        float visibility = saturate(distance / sphereRadius);
        
        // Fade visibility based on distance
        float distanceFraction = traceDistance / AmbientOcclusionMaxDistance;
        visibility = max(visibility, saturate(distanceFraction * distanceFraction * 0.6f));
        
        minVisibility = min(minVisibility, visibility);
        traceDistance += max(distance, minStepSize);

        if (distance < epsilon || traceDistance > AmbientOcclusionMaxDistance) break;
    }
    
    if (minDistance < 0 || step == AmbientOcclusionSteps)
    {
        minVisibility = 0;
    }
    
    return minVisibility;
}

float3 ComputeBentNormal(in Hit hit, in Ray r)
{
    float3 tangent;
    float3 bitangent;
    GetCoordinateSystem(hit.Normal, tangent, bitangent);
    
    float3 bentNormal = 0;
    Ray coneRay;
    coneRay.Origin = hit.Position;
    
    float tanConeAngle = tan((PI/4) / AmbientOcclusionSamples);             //TODO: Revisit
    float rand = hash12(r.uv * 100.) * 2 * PI;
    
    for (int ci = 0; ci < AmbientOcclusionSamples; ci++)
    {
        float3 cDir = HemisphericalFibonacciMapping((float) ci, (float) AmbientOcclusionSamples, rand);
        float3 cDirWorld = cDir.y * bitangent + cDir.x * tangent + cDir.z * hit.Normal; //TODO: Possible error source
        
        coneRay.Direction = cDirWorld;
        
        float cVisibility = GetConeVisibility(coneRay, tanConeAngle);
        
        bentNormal += cVisibility * coneRay.Direction;
    }
    
    bentNormal = bentNormal * (1.0 / (float) AmbientOcclusionSamples);
    
    return bentNormal;
}

void ComputeAO(in Hit hit, in Ray r, out float3 bentNormal, out float diffuseOcclusion, out float specularOcclusion)
{
    //TODO: Improve ao factor computation
    bentNormal = ComputeBentNormal(hit,r);
    float bentNormalLength = length(bentNormal);
    float reflectionConeAngle = max(hit.Material.ReflectiveF, 0.1) * PI;
    float unoccludedAngle = bentNormalLength * PI * SpecularOcclusionStrength;
    float angleBetween = acos(dot(bentNormal, reflect(r.Direction, hit.Normal) / max(bentNormalLength, 0.001)));
    specularOcclusion = ApproxConeConeIntersection(reflectionConeAngle, unoccludedAngle, angleBetween);
    specularOcclusion = lerp(0, specularOcclusion, saturate((unoccludedAngle - 0.1) / 0.2));
    diffuseOcclusion = pow(bentNormalLength, OcclusionExponent);
}

#endif // AMBIENTOCCLUSION_INCLUDED