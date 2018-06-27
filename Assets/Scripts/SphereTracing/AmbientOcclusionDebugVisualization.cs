using System;
using JetBrains.Annotations;
using UnityEditor;
using UnityEngine;
using UnityEngine.Experimental.UIElements;

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
		[Range(0, 2*Mathf.PI)]
		public float ConeAngle = Mathf.PI / 4f;
		
		private int _oldAmbientOcclusionSamplese = -1;
		private float _oldTraceDistance = -1;
		private float _oldConeAngle = -1;

		private void OnDrawGizmos()
		{
			var origin = transform.position;
			
			var normal = DebugSurfaceNormal.normalized;
			var up = Mathf.Abs(normal.y) < 0.999 ? new Vector3(0, 1, 0) : new Vector3(1,0,0);
			var tangent = Vector3.Cross( up, normal ).normalized;
			var bitangent = Vector3.Cross( normal, tangent );
			
			var quaternion = Quaternion.LookRotation(normal, up);
			var prevConeDir = Vector3.zero;

			for (int coneIndex = 0; coneIndex < AmbientOcclusionSamples; coneIndex++)
			{
				var coneDir = Utils.Sampling.HemisphericalFibonacciMapping(coneIndex, AmbientOcclusionSamples, RandomNumber * 2 * Mathf.PI);
				var coneDirWorld = coneDir.x * tangent + coneDir.y * bitangent + coneDir.z * normal;
				//Prevent self occlusion
				coneDirWorld += normal * GetTanConeAngle(ConeAngle);
				coneDirWorld = coneDirWorld.normalized;
				
				GetConeVisibility(coneIndex, origin, coneDirWorld, normal, GetTanConeAngle(ConeAngle));
				
				//Draw sample position as sphere
				if (DrawSamples)
				{
					Gizmos.color = Color.cyan;
					Gizmos.DrawSphere(origin + coneDirWorld, 0.025f);
				}

				//Draw connection between samples positions
				if (DrawConnectedSamples && coneIndex > 0)
				{
					Gizmos.color = new Color(1f, (float)coneIndex/AmbientOcclusionSamples, 1 - (float)coneIndex/AmbientOcclusionSamples, 0.1f);
					Gizmos.DrawLine(origin + prevConeDir, origin + coneDirWorld);
				}
				prevConeDir = coneDirWorld;
				
				if (DrawAllCones || DrawSelectedCone && coneIndex == GizmoConeId)
				{
					Gizmos.color = Color.cyan;
					Gizmos.DrawLine(origin, origin + coneDirWorld);
					
					Gizmos.color = new Color(0f, 1f, 1f, 0.05f);
					var quaternionCone = Quaternion.LookRotation(coneDirWorld, up);
					Gizmos.DrawWireMesh(_coneMesh, origin, quaternionCone);
				}
			}

			if (DrawHemisphere)
			{
				//Draw a Hemisphere for better visualization
				Gizmos.color = new Color(1, 1, 1, 0.01f);
				Gizmos.DrawWireMesh(HemisphereMesh, origin, quaternion);
				Gizmos.color = new Color(1, 1, 1, 0.2f);
				Gizmos.DrawMesh(HemisphereMesh, origin, quaternion);
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

		float GetConeVisibility(int coneIndex, Vector3 origin, Vector3 coneDir, Vector3 normal, float tanConeAngle)
		{
			float traceDistance = 0.1f;
			for (int step = 0; step < AmbientOcclusionSteps; step++)
			{
				float sphereRadius = tanConeAngle * traceDistance;

				if (DrawConeSpheres && DrawSelectedCone && coneIndex == GizmoConeId)
				{
					Gizmos.color = Color.red;
					Gizmos.DrawSphere(origin + traceDistance * coneDir, sphereRadius);
				}

				traceDistance += MaxTraceDistance / AmbientOcclusionSteps;
			}

			return 0;
		}

		float GetTanConeAngle(float coneAngle) { return Mathf.Tan(coneAngle / AmbientOcclusionSamples); }
		
		void OnValidate()
		{
			if (Mathf.Abs(ConeAngle - _oldConeAngle) > Mathf.Epsilon ||
			    Mathf.Abs(MaxTraceDistance - _oldTraceDistance) > Mathf.Epsilon ||
			    AmbientOcclusionSamples != _oldAmbientOcclusionSamplese)
			{
				_coneMesh = CreateConeMesh(10, GetTanConeAngle(ConeAngle) * MaxTraceDistance, MaxTraceDistance);
			}

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

			for(int i = 0, n = subdivisions - 1; i < n; i++) {
				var offset = i * 3;
				triangles[offset] = subdivisions + 1; 
				triangles[offset + 1] = i + 1; 
				triangles[offset + 2] = i + 2; 
			}

			// construct sides

			var bottomOffset = subdivisions * 3;
			for(int i = 0, n = subdivisions - 1; i < n; i++) {
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