#ifndef IMPLICITBASCIS_INCLUDED
#define IMPLICITBASCIS_INCLUDED

float sdSphere(in float3 pos, in float radius)
{
    return length(pos) - radius;
}

#endif // IMPLICITBASCIS_INCLUDED