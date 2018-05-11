using UnityEngine;

namespace SphereTracing.Lights
{
	public struct StLightData
	{
		public int LightType;
		public Vector4 LightData;
		public Vector4 LightData2;
		
		/// <summary>
		/// Returns the size of the struct in Bytes.
		/// </summary>
		/// <remarks>Adjust when changing struct.</remarks>
		/// <returns></returns>
		public static int GetSize()
		{
			return sizeof(int) + 2 * (4 * sizeof(float));
		}
	}
}