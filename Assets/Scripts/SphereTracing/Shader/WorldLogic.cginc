#ifndef WORLDLOGIC_INCLUDED
#define WORLDLOGIC_INCLUDED

#include "UniformVariables.cginc"       //Contains the resources set from CPU.
#include "ImplicitBasics.cginc"
#include "StructDefinitions.cginc"


//Definition of Material IDs
#define MAT_RED 0
#define MAT_GREEN 1
#define MAT_BLUE 2
#define MAT_FLOOR 3

//Objects in the world.

float2 AOTorus(in float3 pos, float mat)
{
    
    float4x4 m = float4x4(1.0,0.0,0.0,0.0,
						  0.0,1.0,0.0,8, 
						  0.0,0.0,1.0,0.0, 
						  0.0,0.0,0.0,1.0);
    float3 p = opTx(pos, m);
    
    float2 q = float2(length(p.xz) - 30., p.y);
    
    return float2(length(q) - 2., mat);
}

float2 SphereTest(in float3 pos,float3 translation, float radius, float mat)
{   
	float4x4 m = float4x4(1.0,0.0,0.0,translation.x,
						  0.0,1.0,0.0,translation.y * sin(Time.x), 
						  0.0,0.0,1.0,translation.z, 
						  0.0,0.0,0.0,1.0);
	float3 pt = opTx(pos, m);
	return float2(sdSphere(pt, radius), mat);
}

float2 BoxTest(in float3 pos)
{
	float3 repeating = float3(10.0, 10.0, 10.0);
	float3 posRepeated = mod(pos, repeating) - 0.5 * repeating;
	return float2(sdBox(posRepeated, float3(4.0, 2.0, 1.0)), MAT_RED);
}

float2 PlaneTest(in float3 pos)
{
	float4x4 m = float4x4(1.0,0.0,0.0,0.0,
						  0.0,1.0,0.0,10.0, 
						  0.0,0.0,1.0,0.0, 
						  0.0,0.0,0.0,1.0);
	float3 pt = opTx(pos, m);
	float plane = sdBox(pt, float3(200.0,2.0,200.0));

	return float2(plane, MAT_FLOOR); 
}
/*
 *  Map
 * 
 *  Map containing all the implicit geometry in the world, aka the function calls of signed distance functions.
 *  Returns float2 with:
 *      x: Signed Distance from position to world.
 *      y: MaterialID of object in world.
 */
float2 Map(in float3 pos)
{
	float2 res = opU(PlaneTest(pos),SphereTest(pos, float3(0.0,8.0,0.0), 6.0, MAT_RED));
	res = opU(res, SphereTest(pos, float3(8.0,1.0,-8.0), 2.0, MAT_RED));
	res = opU(res, SphereTest(pos, float3(-8.0,1.0,-8.0), 2.0, MAT_BLUE));
	res = opU(res, SphereTest(pos, float3(0.0,1.0,8.0), 2.0, MAT_GREEN));
    res = opU(res, AOTorus(pos, MAT_FLOOR));
	//float displacement = displacement = sin(5.0 * pos.x) * sin(5.0 * pos.y) * sin(5.0 * pos.z) * 0.25;
	//res += displacement;
	
	return res;
}

#include "AmbientOcclusion.cginc"

void EvaluateMaterial(inout Hit hit, in Ray r, in float3 normal)
{
	hit.Material = MaterialBuffer[hit.MaterialId];
	
	if (hit.Material.MaterialType == 0) {
		hit.Normal = normal;
	}
}

float3 Shading(in Hit hit, in Ray r)
{
	float3 color = float3(.0, .0, .0);
    float3 bentNormal = hit.Normal;
    float specularOcclusion = 1;
    float diffuseOcclusion = 1;
	
	if (EnableAmbientOcclusion)
        ComputeAO(hit, r, bentNormal, diffuseOcclusion, specularOcclusion);

    for(int i = 0; i < LightCount; i++)
    {
        StLight light = LightBuffer[i];
        if (light.LightType < 0) break;
        if (light.LightType == 0)               // Point Light
        {
            float3 dirToLight = normalize(light.LightData2.xyz - hit.Position);
            float diffuseIntensity = saturate(dot(hit.Normal, dirToLight)) * diffuseOcclusion;
            color += light.LightData.xyz * hit.Material.Color * diffuseIntensity;
        } else if (light.LightType == 1)        // Directional Light
        {
            float diffuseIntensity = saturate(dot(hit.Normal, light.LightData2.xyz)) * diffuseOcclusion;
            color += light.LightData.xyz * hit.Material.Color * diffuseIntensity;
        }
     }
 
	return color;
}

/*
 *  BACKGROUND
 * 
 *  Background/Sky related functions from here on. Need more comments
 */
float3 totalMie(in float T)
{
    float3 MieConst = float3(1.8399918514433978E14, 2.7798023919660528E14, 4.0790479543861094E14 );
    float c = (0.2*T) * 10E-18;
    return 0.434 * c * MieConst;
}

float sunIntensity(in float zenithAngleCos )
{   
	float e = 2.71828182845904523536028747135266249775724709369995957;
	float EE = 1000.0;
	float cutoffAngle = 1.6110731556870734;
	float steepness = 1.5;
	zenithAngleCos = clamp( zenithAngleCos, -1.0, 1.0 );
	return EE * max( 0.0, 1.0 - pow( e, -( ( cutoffAngle - acos( zenithAngleCos)) / steepness ) ) );
}

float hgPhase(in float cosTheta,in float g)
{
	float ONE_OVER_FOURPI = 0.07957747154594767;
	float g2 = pow( g, 2.0);
	float inverse = 1.0 / pow( 1.0 - 2.0 * g * cosTheta + g2, 1.5);
	return ONE_OVER_FOURPI * ( ( 1.0 - g2 ) * inverse );
}

float rayleighPhase(in float cosTheta ) 
{
	float THREE_OVER_SIXTEENPI = 0.05968310365946075;
	return THREE_OVER_SIXTEENPI * ( 1.0 + pow( cosTheta, 2.0 ) );
}

float3 Uncharted2Tonemap(in float3 x)
{
	float A = 0.15;
	float B = 0.50;
	float C = 0.10;
	float D = 0.20;
	float E = 0.02;
	float F = 0.30;
	return ( ( x * ( A * x + C * B ) + D * E ) / ( x * ( A * x + B ) + D * F ) ) - E / F;
}

float3 Background(in Ray r)
{       
	
	float3 sunPosition = float3( 4000.0, 150.0, 7000.0 );
	float3 vSunDirection = normalize( sunPosition );

	float3 up = float3(0.0, 1.0, 0.0);

	float vSunE = sunIntensity( dot( vSunDirection, up ));
	float vSunfade = 1.0 - clamp( 1.0 - exp((sunPosition.y / 450000.0 )), 0.0, 1.0);

	float rayleigh = 2.0;
	float3 totalRayleigh = float3( 5.804542996261093E-6, 1.3562911419845635E-5, 3.0265902468824876E-5 );
	float rayleighCoefficient = rayleigh - (1.0 * (1.0 - vSunfade ));
	float3 vBetaR = totalRayleigh * rayleighCoefficient;

	float turbidity = 10.0;
	float mieCoefficient = 0.005;
	float vBetaM = totalMie( turbidity ) * mieCoefficient;

	float pi = 3.141592653589793238462643383279502884197169;
	float rayleighZenithLength = 8.4E3;
	float mieZenithLength = 1.25E3;
	float zenithAngle = acos(max(0.0, dot( up, normalize(r.Direction) ) ) );
	float inverse = 1.0 / ( cos( zenithAngle ) + 0.15 * pow( 93.885 - ( ( zenithAngle * 180.0 ) / pi ), -1.253) );
	float sR = rayleighZenithLength * inverse;
	float sM = mieZenithLength * inverse;

	float3 Fex = exp( -( vBetaR * sR + vBetaM * sM) );

	float cosTheta = dot( normalize(r.Direction), vSunDirection );
	float rPhase = rayleighPhase( cosTheta * 0.5 + 0.5);
	float3 betaRTheta = vBetaR * rPhase;

	float mieDirectionalG = 0.8;
	float mPhase = hgPhase( cosTheta, mieDirectionalG);
	float3 betaMTheta = vBetaM * mPhase;

	float3 Lin = pow( vSunE * ( ( betaRTheta + betaMTheta ) / ( vBetaR + vBetaM ) ) * ( 1.0 - Fex ), float3( 1.5 , 1.5, 1.5) );
	Lin *= lerp( float3( 1.0,1.0,1.0 ), pow( vSunE * ( ( betaRTheta + betaMTheta ) / ( vBetaR + vBetaM ) ) * Fex, float3( 1.0 / 2.0, 1.0 / 2.0, 1.0 / 2.0 ) ), clamp( pow( 1.0 - dot( up, vSunDirection ), 5.0 ), 0.0, 1.0 ) );

	float theta = acos(r.Direction.y);
	float phi = atan2(r.Direction.z, r.Direction.x);
	float2 uv = float2(phi, theta);
	float3 L0 = float3(0.1,0.1,0.1) * Fex;

	float sunAngularDiameterCos = 0.999956676946448443553574619906976478926848692873900859324;
	float sundisk = smoothstep( sunAngularDiameterCos, sunAngularDiameterCos + 0.00002, cosTheta);
	L0 += ( vSunE * 19000.0 * Fex) * sundisk;

	float luminance = 1.0;
	float whiteScale = 1.0748724675633854;
	float3 texColor = (Lin + L0) * 0.04 + float3(0.0, 0.0003, 0.00075);
	float3 curr = Uncharted2Tonemap( ( log2( 2.0 / pow( luminance, 4.0 ) ) ) * texColor );
	float3 color = curr * whiteScale;

	float retc =  1.0 / ( 1.2 + ( 1.2 * vSunfade ) );
	float3 retColor = pow( color, float3(retc, retc, retc));

	//return r.Direction;
	return retColor;
}

#endif // WORLDLOGIC_INCLUDED