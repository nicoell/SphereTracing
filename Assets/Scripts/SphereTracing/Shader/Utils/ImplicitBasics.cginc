#ifndef IMPLICITBASCIS_INCLUDED
#define IMPLICITBASCIS_INCLUDED

#define mod(x, y) (x - y * floor(x / y))

// Primitives

float sdSphere(float3 p, float radius)
{
	return length(p) - radius;
}

float udBox(float3 p, float3 bounds)
{
	return length(max(abs(p) - bounds, 0.0));
}

float udRoundBox(float3 p, float3 bounds, float radius)
{
	return length(max(abs(p) - bounds, 0.0)) - radius;
}

float sdBox(float3 p, float3 bounds)
{
	float3 d = abs(p) - bounds;
	return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdTorus(float3 p, float2 t)
{
  float2 q = float2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdCone(float3 p, float2 c)
{
	// c must be normalized
	float q = length(p.xy);
	return dot(c,float2(q,p.z));
}

float sdPlane(float3 p, float4 n)
{
  // n must be normalized
  return dot(p,n.xyz) + n.w;
}

float sdHexPrism(float3 p, float2 h)
{
	float3 q = abs(p);
	return max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x);
}

float sdTriPrism(float3 p, float2 h)
{
	float3 q = abs(p);
	return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
}

float sdCapsule(float3 p, float3 a, float3 b, float r)
{
	float3 pa = p - a, ba = b - a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h ) - r;
}

float sdCappedCylinder(float3 p, float2 h)
{
  float2 d = abs(float2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdCappedCone(in float3 p, in float3 c)
{
	float2 q = float2( length(p.xz), p.y );
	float2 v = float2( c.z*c.y/c.x, -c.z );
	float2 w = v - q;
	float2 vv = float2( dot(v,v), v.x*v.x );
	float2 qv = float2( dot(v,w), v.x*w.x );
	float2 d = max(qv,0.0)*qv/vv;
	return sqrt( dot(w,w) - max(d.x,d.y) ) * sign(max(q.y*v.x-q.x*v.y,w.y));
}

float sdEllipsoid(in float3 p, in float3 r)
{
	return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}

//Distance Operations

//Union
float2 opU( float2 d1, float2 d2 )
{
	return (d1.x < d2.x) ? d1 : d2;
}

//Subtraction
float2 opS( float2 d1, float2 d2 )
{
	return (-d1.x > d2.x) ? float2(-d1.x, d1.y) : d2;
}

//Intersection
float2 opI( float2 d1, float2 d2 )
{
	return (d1.x > d2.x) ? d1 : d2;
}

//Domain Operations

//Repetition
float3 opRep(float3 p, float3 c)
{
	return mod(p, c) - 0.5*c;
}

//Rotation/Translation
float3 opTx(float3 p, float4x4 m)
{
	return mul(m, float4(p, 1)).xyz;
}

float3 opScale( float3 p, float s )
{
    return (p*s)/s;
}

//Domain Deformations

//Twist
float3 opTwist(float3 p)
{
	float c = cos(20.0*p.y);
	float s = sin(20.0*p.y);
	float2x2 m = float2x2(c, -s, s, c);
	return float3(mul(m, p.xz), p.y);
}

//Bend
float3 opBend(float3 p)
{
	float c = cos(20.0*p.y);
	float s = sin(20.0*p.y);
	float2x2 m = float2x2(c, -s, s, c);
	return float3(mul(m, p.xy), p.z);
}

#endif // IMPLICITBASCIS_INCLUDED