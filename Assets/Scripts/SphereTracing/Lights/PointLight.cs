using UnityEngine;

namespace SphereTracing.Lights {
	public class PointLight : StLight
	{
		private const int LIGHT_TYPE = 0;
		public override int LightType { get { return LIGHT_TYPE; } }

		[Header("Point Light Settings")]
		public Color LightColor = Color.white;

		public override StLightData GetStLightData()
		{
			var data = new StLightData
			{
				LightType = IsActive ? LIGHT_TYPE : -1,
				LightData = LightColor,
				LightData2 = transform.position
			};

			return data;
		}

		private void OnDrawGizmos()
		{
			Gizmos.color = LightColor;
			Gizmos.DrawWireSphere(transform.position, 0.5f);
			Gizmos.DrawIcon(transform.position, "stLight_Point");
		}
	}
}