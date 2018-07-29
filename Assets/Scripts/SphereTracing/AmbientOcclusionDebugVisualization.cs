using System;
using JetBrains.Annotations;
using UnityEditor;
using UnityEngine;
using UnityEngine.Experimental.UIElements;
using Utils;
using Random = UnityEngine.Random;

namespace SphereTracing
{
	[ExecuteInEditMode]
	public class AmbientOcclusionDebugVisualization : MonoBehaviour
	{
		[Header("Dependencies")]
		public Mesh HemisphereMesh;
		private Mesh _coneMesh;
		[Header("Gizmo Options")]
		public bool DrawConnectedSamples;
		public bool DrawSamples;
		public bool DrawCoordinateSystem;
		public bool DrawHemisphere;
		public bool DrawAllCones;
		public bool DrawSelectedCone;
		public bool DrawConeSpheres;
		[Range(0, 31)]
		public int GizmoConeId = 0;
		
		[Header("Ambient Occlusion Settings")]
		public Vector3 DebugSurfaceNormal = Vector3.up;
		[Range(1, 32)]
		public int AmbientOcclusionSamples = 1;
		[Range(1, 32)]
		public int AmbientOcclusionSteps = 1;
		[Range(0, 1)]
		public float RandomNumber;
		public float MaxTraceDistance;
		public bool CorrectSamplesWithConeAngle;
		[Range(0, 2*Mathf.PI)]
		public float ConeAngle = Mathf.PI / 4f;

		private System.Random _random;
		private int _oldAmbientOcclusionSamplese = -1;
		private float _oldTraceDistance = -1;
		private float _oldConeAngle = -1;

		private void OnDrawGizmos()
		{
			var origin = transform.position;

			var normal = DebugSurfaceNormal.normalized;
			var up = Mathf.Abs(normal.y) < 0.999 ? new Vector3(0, 1, 0) : new Vector3(1, 0, 0);
			var tangent = Vector3.Cross(up, normal).normalized;
			var bitangent = Vector3.Cross(normal, tangent);

			var quaternion = Quaternion.LookRotation(normal, up);
			var prevConeDir = Vector3.zero;

			if (DrawHemisphere)
			{
				Gizmos.color = new Color(1, 1, 1, 0.04f);
				Gizmos.DrawMesh(HemisphereMesh, origin, quaternion);
				//Draw a Hemisphere for better visualization
				Gizmos.color = new Color(0, 0, 0, 0.3f);
				Gizmos.DrawWireMesh(HemisphereMesh, origin, quaternion);
			}
			
			for (var coneIndex = 0; coneIndex < AmbientOcclusionSamples; coneIndex++)
			{
				
				var coneDir = Sampling.HemisphericalFibonacciMapping(coneIndex, AmbientOcclusionSamples,
					RandomNumber * 2 * Mathf.PI, CorrectSamplesWithConeAngle ? GetTanConeAngle(ConeAngle) : Mathf.Clamp01(ConeAngle));
				var coneDirWorld = coneDir.x * tangent + coneDir.y * bitangent + coneDir.z * normal;
				
				var coneColor = new Color(1f, 1f, 1f, 0.1f);
				coneColor.r = Mathf.Abs(coneDir.x);
				coneColor.g = Mathf.Abs(coneDir.y);//coneDir.y;
				coneColor.b = Mathf.Sin(coneDir.z);//Mathf.Sin(Mathf.Abs(coneDir.z) * Mathf.PI);
				
				//Prevent self occlusion
				//coneDirWorld += normal * GetTanConeAngle(ConeAngle);
				//coneDirWorld = coneDirWorld.normalized;

				GetConeVisibility(coneIndex, origin, coneDirWorld, normal, GetTanConeAngle(ConeAngle));

				//Draw sample position as sphere
				if (DrawSamples)
				{
					var sampleColor = coneColor * 4;
					sampleColor.a = 0.7f;
					Gizmos.color = sampleColor;
					Gizmos.DrawSphere(origin + coneDirWorld * MaxTraceDistance, 0.025f);
				}

				//Draw connection between samples positions
				if (DrawConnectedSamples && coneIndex > 0)
				{
					Gizmos.color = coneColor;
					Gizmos.DrawLine(origin + prevConeDir * MaxTraceDistance, origin + coneDirWorld * MaxTraceDistance);
				}

				prevConeDir = coneDirWorld;

				if (DrawAllCones)
				{
					var sampleColor = coneColor;
					sampleColor.a = 0.7f;
					Gizmos.color = sampleColor;
					Gizmos.DrawLine(origin, origin + coneDirWorld * MaxTraceDistance);
				}
				if (DrawSelectedCone && coneIndex == GizmoConeId)
				{
					var sampleColor = coneColor;
					if (!CorrectSamplesWithConeAngle) sampleColor.a = 0.7f;
					Gizmos.color = sampleColor;
					Gizmos.DrawLine(origin, origin + coneDirWorld * MaxTraceDistance);

					Gizmos.color = coneColor;
					var quaternionCone = Quaternion.LookRotation(coneDirWorld, up);
					if (CorrectSamplesWithConeAngle) Gizmos.DrawWireMesh(_coneMesh, origin, quaternionCone);
				}
			}
			

			

			if (DrawCoordinateSystem)
			{
				Gizmos.color = Color.red;
				Gizmos.DrawLine(origin, origin + tangent);
				Gizmos.color = Color.green;
				Gizmos.DrawLine(origin, origin + normal);
				Gizmos.color = Color.blue;
				Gizmos.DrawLine(origin, origin + bitangent);
			}
		}
		
		private float GetConeVisibility(int coneIndex, Vector3 origin, Vector3 coneDir, Vector3 normal,
			float tanConeAngle)
		{
			var traceDistance = 0.1f;
			for (var step = 0; step < AmbientOcclusionSteps; step++)
			{
				var sphereRadius = tanConeAngle * traceDistance;

				if (DrawConeSpheres && DrawSelectedCone && coneIndex == GizmoConeId)
				{
					Gizmos.color = Color.red;
					Gizmos.DrawSphere(origin + traceDistance * coneDir, sphereRadius);
				}

				traceDistance += MaxTraceDistance / AmbientOcclusionSteps;
			}

			return 0;
		}

		private float GetTanConeAngle(float coneAngle) { return Mathf.Tan(coneAngle / AmbientOcclusionSamples); }

		private void OnValidate()
		{
			if (Mathf.Abs(ConeAngle - _oldConeAngle) > Mathf.Epsilon ||
			    Mathf.Abs(MaxTraceDistance - _oldTraceDistance) > Mathf.Epsilon ||
			    AmbientOcclusionSamples != _oldAmbientOcclusionSamplese)
				_coneMesh = CreateConeMesh(24, GetTanConeAngle(ConeAngle) * MaxTraceDistance, MaxTraceDistance);

			_oldConeAngle = ConeAngle;
			_oldTraceDistance = MaxTraceDistance;
			_oldAmbientOcclusionSamplese = AmbientOcclusionSamples;
		}

		/*
		 * Based on gist from github User mattatz
		 * Updated for wireframe use only
		 * https://gist.github.com/mattatz/aba0d06fa56ef65e45e2
		 */
		private static Mesh CreateConeMesh(int subdivisions, float radius, float height)
		{
			var mesh = new Mesh();

			var vertices = new Vector3[subdivisions + 2];
			var uv = new Vector2[vertices.Length];
			var triangles = new int[subdivisions * 2 * 3];

			vertices[0] = Vector3.zero;
			uv[0] = new Vector2(0f, 0.5f);
			for (int i = 0, n = subdivisions - 1; i < subdivisions; i++)
			{
				var ratio = (float) i / n;
				var r = ratio * (Mathf.PI * 2f);
				var x = Mathf.Cos(r) * radius;
				var z = Mathf.Sin(r) * radius;
				vertices[i + 1] = new Vector3(x, z, height);

				//Debug.Log (ratio);
				uv[i + 1] = new Vector2(ratio, 0f);
			}

			vertices[subdivisions + 1] = new Vector3(0f, 0f, 0f);
			uv[subdivisions + 1] = new Vector2(0.5f, 1f);

			// construct bottom

			for (int i = 0, n = subdivisions - 1; i < n; i++)
			{
				var offset = i * 3;
				triangles[offset] = subdivisions + 1;
				triangles[offset + 1] = i + 1;
				triangles[offset + 2] = i + 2;
			}

			// construct sides

			var bottomOffset = subdivisions * 3;
			for (int i = 0, n = subdivisions - 1; i < n; i++)
			{
				var offset = i * 3 + bottomOffset;
				triangles[offset] = i + 1;
				triangles[offset + 1] = subdivisions + 1;
				triangles[offset + 2] = i + 2;
			}

			mesh.vertices = vertices;
			mesh.uv = uv;
			mesh.triangles = triangles;
			mesh.RecalculateBounds();
			mesh.RecalculateNormals();

			return mesh;
		}
	}
}