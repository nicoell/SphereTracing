using System.Collections.Generic;
using System.Linq;
using SphereTracing.Lights;
using SphereTracing.Materials;
using UnityEngine;

namespace SphereTracing
{
	public class SphereTracingManager : MonoBehaviour
	{
		private ComputeKernel[] _computeKernels;
		private RenderTexture _targetRenderTexture;
		private Resolution _targetResolution;
		
		#region PublicVariables Adjustable in Editor

		[Header("Dependencies")]
		public ComputeShader SphereTracingShader;

		[Header("Quality and Resolution Settings")]
		public bool UseCustomResolution;
		public Vector2Int CustomResolution;
		[Tooltip("Kernels have a different ThreadGroupSizes. 0: High; 1: Mid; 2: Low Size.")]
		[Range(0, 2)]
		public int ComputeShaderKernel;
		[Range(2, 1024)]
		public int SphereTracingSteps = 32;

		[Header("Features")]
		public bool EnableSuperSampling;
		public int LightCount = 1;

		public bool EnableAmbientOcclusion;
		[Range(1, 32)]
		public int AmbientOcclusionSamples = 5;
		[Range(1, 32)]
		public int AmbientOcclusionSteps = 5;
		[Range(0.01f, 100f)]
		public float AmbientOcclusionMaxDistance = 1.0f;
		[Range(0.01f, 3f)]
		public float SpecularOcclusionStrength = 1.0f;
		[Range(0.01f, 3f)]
		public float OcclusionExponent = 1.0f;
		[Range(0f, 1f)]
		public float BentNormalFactor = 1.0f;

		public bool EnableGlobalIllumination;

		public Vector3 GammaCorrection = Vector3.one;

		#endregion
		
		// Use this for initialization
		public void Awake()
		{
			OnDestroy();
			if (UseCustomResolution)
				_targetResolution = new Resolution
				{
					width = CustomResolution.x,
					height = CustomResolution.y
				};
			else _targetResolution = Screen.currentResolution;

			// Create Render Texture
			_targetRenderTexture = new RenderTexture(_targetResolution.width, _targetResolution.height, 0,
				RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear)
			{
				enableRandomWrite = true
			};
			_targetRenderTexture.Create();

			_computeKernels = new ComputeKernel[3];
			_computeKernels[0].Name = "CSMainHigh";
			_computeKernels[1].Name = "CSMainMid";
			_computeKernels[2].Name = "CSMainLow";

			for (var i = 0; i < _computeKernels.Length; i++)
			{
				_computeKernels[i].Id = SphereTracingShader.FindKernel(_computeKernels[i].Name);
				uint threadGroupX, threadGroupY, threadGroupZ;
				SphereTracingShader.GetKernelThreadGroupSizes(_computeKernels[i].Id, out threadGroupX,
					out threadGroupY, out threadGroupZ);
				_computeKernels[i].ThreadGroupSize = new Vector3Int((int) threadGroupX, (int) threadGroupY, (int) threadGroupZ);
				_computeKernels[i].CalculateThreadGroups(_targetResolution.width, _targetResolution.height, 1);
			}

			//Set resolution and texture in ComputeShader
			SphereTracingShader.SetFloats("Resolution", _targetResolution.width, _targetResolution.height);

			InitLights();
			InitMaterials();
		}

		// Update is called once per frame
		private void Update()
		{
			UpdateStLights();
			UpdateStMaterials();

			SphereTracingShader.SetTexture(_computeKernels[ComputeShaderKernel].Id, "SphereTracingTexture",
				_targetRenderTexture);
			SphereTracingShader.SetVectorArray("CameraFrustumEdgeVectors", GetCameraFrustumEdgeVectors(Camera.main));
			SphereTracingShader.SetMatrix("CameraInverseViewMatrix", Camera.main.cameraToWorldMatrix);
			SphereTracingShader.SetVector("CameraPos", Camera.main.transform.position);
			SphereTracingShader.SetVector("CameraDir", Camera.main.transform.forward);
			SphereTracingShader.SetFloats("ClippingPlanes", Camera.main.nearClipPlane, Camera.main.farClipPlane);
			SphereTracingShader.SetVector("Time", new Vector4(Time.time, Time.time / 20f, Time.deltaTime, 1f / Time.deltaTime));

			SphereTracingShader.SetInt("SphereTracingSteps", SphereTracingSteps);
			SphereTracingShader.SetBool("EnableSuperSampling", EnableSuperSampling);

			SphereTracingShader.SetBool("EnableAmbientOcclusion", EnableAmbientOcclusion);
			SphereTracingShader.SetInt("AmbientOcclusionSamples", AmbientOcclusionSamples);
			SphereTracingShader.SetInt("AmbientOcclusionSteps", AmbientOcclusionSteps);
			SphereTracingShader.SetFloat("AmbientOcclusionMaxDistance", AmbientOcclusionMaxDistance);
			SphereTracingShader.SetFloat("SpecularOcclusionStrength", SpecularOcclusionStrength);
			SphereTracingShader.SetFloat("OcclusionExponent", OcclusionExponent);
			SphereTracingShader.SetFloat("BentNormalFactor", BentNormalFactor);
			SphereTracingShader.SetBool("EnableGlobalIllumination", EnableGlobalIllumination);
			
			SphereTracingShader.SetVector("GammaCorrection", GammaCorrection);
			
			SphereTracingShader.Dispatch(_computeKernels[ComputeShaderKernel].Id,
				_computeKernels[ComputeShaderKernel].ThreadGroups.x,
				_computeKernels[ComputeShaderKernel].ThreadGroups.y,
				_computeKernels[ComputeShaderKernel].ThreadGroups.z);
		}

		private void OnRenderImage(RenderTexture src, RenderTexture dest)
		{
			//Render Texture on Screen
			Graphics.Blit(_targetRenderTexture, (RenderTexture) null);
		}

		private void OnDrawGizmos() { Gizmos.DrawSphere(Vector3.zero, 3f); }

		private void OnDrawGizmosSelected()
		{
			//Draw Camera Frustum Edge Vectors
			var cameraFrustumEdgeVectors = GetCameraFrustumEdgeVectors(Camera.main);
			foreach (var edge in cameraFrustumEdgeVectors)
			{
				Gizmos.color = Color.green;
				Gizmos.DrawRay(Camera.main.transform.position, Camera.main.cameraToWorldMatrix.MultiplyVector(edge));
			}
		}

		/// <summary>
		///     Returns the 4 edge vectors of the frustum of the given camera.
		/// </summary>
		/// <param name="camera">Unity camera object.</param>
		/// <returns>Array of Vectors with 4 not-normalized vectors. </returns>
		private static Vector4[] GetCameraFrustumEdgeVectors(Camera camera)
		{
			var frustumVectors = new Vector4[4];
			var tanFov = Mathf.Tan(camera.fieldOfView * 0.5f * Mathf.Deg2Rad);
			var right = Vector3.right * tanFov * camera.aspect;
			var top = Vector3.up * tanFov;

			frustumVectors[0] = (-Vector3.forward - right + top).normalized; //TopLeft
			frustumVectors[1] = (-Vector3.forward + right + top).normalized; //TopRight
			frustumVectors[2] = (-Vector3.forward + right - top).normalized; //BottomRight
			frustumVectors[3] = (-Vector3.forward - right - top).normalized; //BottomLeft

			return frustumVectors;
		}

		private void OnDestroy()
		{
			if (_stLightBuffer != null) _stLightBuffer.Release();
			if (_stMaterialBuffer != null) _stMaterialBuffer.Release();
			if (_targetRenderTexture != null) DestroyImmediate(_targetRenderTexture);
		}

		protected struct ComputeKernel
		{
			public string Name;
			public int Id;
			public Vector3Int ThreadGroupSize;
			public Vector3Int ThreadGroups;

			public void CalculateThreadGroups(int totalThreadsX, int totalThreadsY, int totalThreadsZ)
			{
				ThreadGroups = new Vector3Int
				{
					x = totalThreadsX / ThreadGroupSize.x,
					y = totalThreadsY / ThreadGroupSize.y,
					z = totalThreadsZ / ThreadGroupSize.z
				};
			}
		}

		#region Light

		private StLightData[] _stLightData;
		private List<StLight> _stLights;
		private ComputeBuffer _stLightBuffer;

		private void InitLights()
		{
			_stLightData = new StLightData[LightCount];
			_stLightBuffer = new ComputeBuffer(LightCount, StLightData.GetSize(), ComputeBufferType.Default);
			_stLightBuffer.SetData(_stLightData);
			if (_stLights == null) _stLights = new List<StLight>();

			SphereTracingShader.SetInt("LightCount", LightCount);
		}

		public void RegisterStLight(StLight stLight)
		{
			if (_stLights != null && _stLights.All(item => item.GetInstanceID() != stLight.GetInstanceID())) _stLights.Add(stLight);
		}

		public void CleanStLights() { _stLights.RemoveAll(lights => lights == null || !lights.IsActive); }

		private void UpdateStLights()
		{
			var i = 0;

			foreach (var stLight in _stLights)
			{
				_stLightData[i] = stLight.GetStLightData();
				i++;
				if (i >= _stLightData.Length)
				{
					if (i > _stLightData.Length) Debug.LogWarning("There are more lights in the scene than the light buffer can store."); 
					break; 
				}
			}

			for (var c = i; c < _stLightData.Length; c++) _stLightData[c].LightType = -1;

			_stLightBuffer.SetData(_stLightData);

			SphereTracingShader.SetBuffer(_computeKernels[ComputeShaderKernel].Id, "LightBuffer", _stLightBuffer);
		}

		#endregion
		
		#region Material

		public StMaterial[] StMaterials;
		private ComputeBuffer _stMaterialBuffer;

		private void InitMaterials()
		{
			_stMaterialBuffer = new ComputeBuffer(StMaterials.Length, StMaterialData.GetSize(), ComputeBufferType.Default);
			_stMaterialBuffer.SetData(StMaterials.Select(x => x.MaterialData).ToArray());

			SphereTracingShader.SetInt("MaterialCount", StMaterials.Length);
		}
		
		private void UpdateStMaterials()
		{
			_stMaterialBuffer.SetData(StMaterials.Select(x => x.MaterialData).ToArray());

			SphereTracingShader.SetBuffer(_computeKernels[ComputeShaderKernel].Id, "MaterialBuffer", _stMaterialBuffer);
		}
		
		#endregion
	}
}