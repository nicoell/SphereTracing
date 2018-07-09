using UnityEngine;

namespace SphereTracing.Materials
{	
	[CreateAssetMenu(menuName = "SphereTracing/Material")]
	public class StMaterial : ScriptableObject
	{
		public StMaterialData MaterialData;
	}
	
	[System.Serializable]
	public struct StMaterialData
	{
		public int MaterialType;
		public Color BaseColor;
		public Color EmissiveColor;
		[Range(0, 1)]
		public float Metallic;
		[Range(0, 1)]
		public float PerceptualRoughness;
		[Range(0, 16)]
		public float RimFactor;
		
		/// <summary>
		/// Returns the size of the struct in Bytes.
		/// </summary>
		/// <remarks>Adjust when changing struct.</remarks>
		/// <returns></returns>
		public static int GetSize()
		{
			return sizeof(int) + 11 * sizeof(float);
		}
	}
}