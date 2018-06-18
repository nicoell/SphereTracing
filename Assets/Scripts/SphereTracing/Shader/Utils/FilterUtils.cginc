#ifndef FILTERUTILS_INCLUDED
#define FILTERUTILS_INCLUDED

bool CheckerBoard(in float2 uv, in float2 size)
{
    bool p = fmod(uv.x * size.x, 2.0) < 1.0;
    bool q = fmod(uv.y * size.y, 2.0) > 1.0;
    return (p && q) || !(p || q);
}

float max4(float a, float b, float c, float d)
{
    return max(max(max(a, b), c), d);
}

float max4(float4 v)
{
    return max4(v.x, v.y, v.z, v.w);
}

float min4(float a, float b, float c, float d)
{
    return min(min(min(a, b), c), d);
}

float min4(float4 v)
{
    return min4(v.x, v.y, v.z, v.w);
}

int IndexOfMaxComponent(float4 v)
{
    float maxComp = max4(v.x, v.y, v.z, v.w);
    if (step(maxComp, v.x)) return 0;
    if (step(maxComp, v.y)) return 1;
    if (step(maxComp, v.z)) return 2;
    /*if (step(maxComp, v.w))*/ return 3;
}

int IndexOfMinComponent(float4 v)
{
    float minComp = min4(v.x, v.y, v.z, v.w);
    if (step(v.x, minComp)) return 0;
    if (step(v.y, minComp)) return 1;
    if (step(v.z, minComp)) return 2;
    /*if (step(v.w, minComp))*/ return 3;
}

#endif // FILTERUTILS_INCLUDED