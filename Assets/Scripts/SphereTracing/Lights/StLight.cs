using System;
using UnityEngine;

namespace SphereTracing.Lights
{
	/// <inheritdoc />
	/// <summary>
	///     Sphere Tracing Light.
	/// </summary>
	/// <remarks>Class name "Light" would conflict with unity.</remarks>
	public abstract class StLight : MonoBehaviour
	{
		[HideInInspector]
		public bool IsActive = true;
		public SphereTracingManager SphereTracingManager;
		public abstract int LightType { get; }

		public abstract StLightData GetStLightData();

		protected void Start()
		{
			IsActive = true;
			SphereTracingManager.RegisterStLight(this);
		}

		protected void OnDisable()
		{
			IsActive = false;
			SphereTracingManager.CleanStLights();
		}
		
		protected void OnEnable()
		{
			if (IsActive) return;
			IsActive = true;
			SphereTracingManager.RegisterStLight(this);
		}

		protected void OnDestroy()
		{
			IsActive = false;
			SphereTracingManager.CleanStLights();
		}
	}
}