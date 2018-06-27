using UnityEngine;

namespace Utils
{
	public static class Sampling
	{
		private const float PI = 3.141592653589793238f;
		private const float GOLDENRATIO = 1.6180339887498948f;//Golden Ratio = (1 + sqrt(5)) / 2
		
		public static Vector3 HemisphericalFibonacciMapping(float i, float n, float rand)
		{
			float phi = i * 2.0f * PI * GOLDENRATIO + rand;
			float zi = 1.0f - (2.0f*i+1.0f)/(2.0f*n);
			float theta = Mathf.Sqrt(1.0f - zi*zi);
			return new Vector3( Mathf.Cos(phi) * theta, Mathf.Sin(phi) * theta, zi).normalized;
		}
	}
}