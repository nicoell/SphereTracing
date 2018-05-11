using UnityEngine;

namespace SphereTracing.Lights {
	public class DirectionalLight : StLight
	{
		private const int LIGHT_TYPE = 1;
		public override int LightType { get { return LIGHT_TYPE; } }

		[Header("Directional Light Settings")]
		public Color LightColor = Color.white;

		public override StLightData GetStLightData()
		{
			var data = new StLightData
			{
				LightType = IsActive ? LIGHT_TYPE : -1,
				LightData = LightColor,
				LightData2 = transform.forward
			};

			return data;
		}

		private void OnDrawGizmos()
		{
			Gizmos.color = LightColor;
			Gizmos.DrawRay(transform.position, transform.forward);
			Gizmos.DrawIcon(transform.position, "stLight_Directional");
		}
	}
}