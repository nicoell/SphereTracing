using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using SphereTracing.DeferredRendering;
using SphereTracing.Lights;
using SphereTracing.Materials;
using UnityEngine;
using UnityEngine.Rendering;


namespace SphereTracing
{
	[SuppressMessage("ReSharper", "UnusedMember.Global")]
	public enum RenderOutput
	{
		Color = 0,
		SurfaceColor, 
		RepresentColor,
		SurfacePosition,
		SurfaceMaterialId,
		SurfaceRayDirection,
		SurfaceDepth,
		SurfaceNormal,
		SurfaceAlpha,
		SurfaceBentNormal,
		SurfaceDiffuseOcclusion,
		SurfaceSpecularOcclusion,
		RepresentPosition,
		RepresentMaterialId,
		RepresentRayDirection,
		RepresentDepth,
		RepresentNormal,
		RepresentAlpha,
		RepresentBentNormal,
		RepresentDiffuseOcclusion,
		RepresentSpecularOcclusion,
		SurfaceLowResDepth
		
	}
	
	public class SphereTracingManager : MonoBehaviour
	{
		private ComputeKernel[] _sphereTracingFKernels;
		private ComputeKernel[] _sphereTracingKKernels;
		private ComputeKernel[] _sphereTracingAoKernels;
		private ComputeKernel[] _horizontalBilateralFilterKernels;
		private ComputeKernel[] _verticalBilateralFilterKernels;
		private ComputeKernel[] _deferredKernels;
		private int _prevComputeKernel;
		private Resolution _targetResolution;
		private RenderTexture _deferredOutput;
		private RenderTexture _sphereTracingData;
		private RenderTexture _downsampledSphereTracingData;
		
		#region PublicVariables Adjustable in Editor

		[Header("Dependencies")]
		public ComputeShader SphereTracingShader;
		public ComputeShader BilateralFilterShader;
		public ComputeShader DeferredShader;
		
		[Header("Resolution")]
		public bool UseCustomResolution;
		public Vector2Int CustomResolution;
		
		[Header("Quality Settings")]
		[Tooltip("Kernels have a different ThreadGroupSizes. 0: High; 1: Mid; 2: Low Size.")]
		[Range(0, 2)]
		public int ComputeShaderKernel;
		[Range(2, 1024)]
		public int SphereTracingSteps = 32;
		[Range(0, 32)]
		public int IterativeSteps = 0;
		[Header("Render Settings")]
		public RenderOutput RenderOutput = RenderOutput.Color;
		public Vector3 GammaCorrection = Vector3.one;

		[Header("Anti Aliasing")]
		[Range(0.001f, 1f)]
		public float RadiusPixel = 0.01f;
		
		[Header("Features")]
		public bool EnableSuperSampling;
		public int LightCount = 1;
		public Color ClearColor = Color.black;
		
		[Header("Ambient Occlusion")]
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
		[Space(10)]
		public bool EnableGlobalIllumination;
		public bool EnableCrossBilateralFiltering;
		[Range(0f, 10f)]
		public float RangeSigma = 0.0051f;
		[Range(1, 32)]
		public int FilterSteps = 1;
		[Space(10)]
		[Range(0f, 10f)]
		public float NearestDepthThreshold = 0.0051f;
		[Space(10)]
		[Tooltip("Control the resolution of ambient occlusion rendering.")]
		public DeferredRenderTarget AmbientOcclusionDrt;

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
			_deferredOutput = new RenderTexture(_targetResolution.width, _targetResolution.height, 0,
				RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear)
			{
				enableRandomWrite = true
			};
			_deferredOutput.Create();
			
			_sphereTracingData = new RenderTexture(_targetResolution.width, _targetResolution.height, 0,
				RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear)
			{
				enableRandomWrite = true,
				useMipMap = false,
				autoGenerateMips = false,
				dimension = TextureDimension.Tex2DArray,
				volumeDepth = 6
			};
			_sphereTracingData.Create();
			
			AmbientOcclusionDrt.Init("AmbientOcclusion", _targetResolution, RenderTextureFormat.ARGBFloat, TextureDimension.Tex2DArray, 2);
			
			_sphereTracingFKernels = InitComputeKernels(SphereTracingShader, _targetResolution, 1, "SphereTracingFPassH",
				"SphereTracingFPassM", "SphereTracingFPassL"); 
			_sphereTracingKKernels = InitComputeKernels(SphereTracingShader, _targetResolution, 1, "SphereTracingKPassH",
				"SphereTracingKPassM", "SphereTracingKPassL"); 
			_sphereTracingAoKernels = InitComputeKernels(SphereTracingShader, AmbientOcclusionDrt.Resolution, 1, "AmbientOcclusionH",
				"AmbientOcclusionM", "AmbientOcclusionL");
			_horizontalBilateralFilterKernels = InitComputeKernels(BilateralFilterShader, _targetResolution, 2,
				"AOHorizontalH", "AOHorizontalM", "AOHorizontalL");
			_verticalBilateralFilterKernels = InitComputeKernels(BilateralFilterShader, _targetResolution, 2,
				"AOVerticalH", "AOVerticalM", "AOVerticalL");
			_deferredKernels = InitComputeKernels(DeferredShader, _targetResolution, 1, "DeferredH", "DeferredM", "DeferredL");
			_deferredKernels = InitComputeKernels(DeferredShader, _targetResolution, 1, "DeferredH", "DeferredM", "DeferredL");

			SetShaderPropertiesOnce();
			InitLights();
			InitMaterials();
		}

		

		private void SetShaderPropertiesOnce()
		{
			Shader.SetGlobalFloat("AoTargetMip", AmbientOcclusionDrt.TargetMip);
			//Cannot set bool/floats globally. For simplicity we do it for all computeShaders
			var computeShaders = new[] { SphereTracingShader, BilateralFilterShader, DeferredShader};
			foreach (var computeShader in computeShaders)
			{
				computeShader.SetFloats("Resolution", _targetResolution.width, _targetResolution.height);
				computeShader.SetFloats("AoResolution", AmbientOcclusionDrt.Resolution.width, AmbientOcclusionDrt.Resolution.height);
			}
			//Only bind textures once
			foreach (var kernel in _sphereTracingFKernels)
			{
				SphereTracingShader.SetTexture(kernel.Id, "SphereTracingDataTexture", _sphereTracingData);
			}
			foreach (var kernel in _sphereTracingKKernels)
			{
				SphereTracingShader.SetTexture(kernel.Id, "SphereTracingDataTexture", _sphereTracingData);
			}
			foreach (var kernel in _sphereTracingAoKernels)
			{
				SphereTracingShader.SetTexture(kernel.Id, "SphereTracingDataTexture", _sphereTracingData);
				SphereTracingShader.SetTexture(kernel.Id, "AmbientOcclusionTexture", AmbientOcclusionDrt.RenderTexture);
			}
			foreach (var kernel in _horizontalBilateralFilterKernels)
			{
				BilateralFilterShader.SetTexture(kernel.Id, "SphereTracingDataTexture", _sphereTracingData);
				//BilateralFilterShader.SetTexture(kernel.Id, "AmbientOcclusionTexture", AmbientOcclusionDrt.RenderTexture);
				//BilateralFilterShader.SetTexture(kernel.Id, "AmbientOcclusionTarget", AmbientOcclusionDrt.RenderTexture2);
			}
			foreach (var kernel in _verticalBilateralFilterKernels)
			{
				BilateralFilterShader.SetTexture(kernel.Id, "SphereTracingDataTexture", _sphereTracingData);
				//BilateralFilterShader.SetTexture(kernel.Id, "AmbientOcclusionTexture", AmbientOcclusionDrt.RenderTexture);
				//BilateralFilterShader.SetTexture(kernel.Id, "AmbientOcclusionTarget", AmbientOcclusionDrt.RenderTexture2);
			}
			foreach (var kernel in _deferredKernels)
			{
				DeferredShader.SetTexture(kernel.Id, "SphereTracingDataTexture", _sphereTracingData);
				DeferredShader.SetTexture(kernel.Id, "AmbientOcclusionTexture", AmbientOcclusionDrt.RenderTexture3);
				DeferredShader.SetTexture(kernel.Id, "DeferredOutputTexture", _deferredOutput);
			}
		}

		private void SetShaderPropertiesPerFrame()
		{
			//Note: Materials and Lights are set seperately in respective regions 
			
			//Set Properties global if possible for simplicity
			Shader.SetGlobalFloat("RangeSigma", RangeSigma);
			Shader.SetGlobalFloat("NearestDepthThreshold", NearestDepthThreshold);
			Shader.SetGlobalFloat("OcclusionExponent", OcclusionExponent);
			Shader.SetGlobalFloat("RadiusPixel", RadiusPixel);
			Shader.SetGlobalFloat("AmbientOcclusionMaxDistance", AmbientOcclusionMaxDistance);
			Shader.SetGlobalFloat("SpecularOcclusionStrength", SpecularOcclusionStrength);
			Shader.SetGlobalFloat("BentNormalFactor", BentNormalFactor);
			Shader.SetGlobalInt("RenderOutput", (int) RenderOutput);
			Shader.SetGlobalInt("SphereTracingSteps", SphereTracingSteps);
			Shader.SetGlobalInt("AmbientOcclusionSamples", AmbientOcclusionSamples);
			Shader.SetGlobalInt("AmbientOcclusionSteps", AmbientOcclusionSteps);
			Shader.SetGlobalVector("Time", new Vector4(Time.time, Time.time / 20f, Time.deltaTime, 1f / Time.deltaTime));
			Shader.SetGlobalVector("CameraPos", Camera.main.transform.position);
			Shader.SetGlobalVector("CameraDir", Camera.main.transform.forward);
			Shader.SetGlobalVector("GammaCorrection", GammaCorrection);
			Shader.SetGlobalColor("ClearColor", ClearColor);
			var cameraFrustumEdgeVectors = GetCameraFrustumEdgeVectors(Camera.main);
			var angleX = Mathf.Acos(Vector4.Dot(cameraFrustumEdgeVectors[0], cameraFrustumEdgeVectors[1])) / _targetResolution.width;
			var angleY = Mathf.Acos(Vector4.Dot(cameraFrustumEdgeVectors[0], cameraFrustumEdgeVectors[3])) / _targetResolution.height;
			Shader.SetGlobalVectorArray("CameraFrustumEdgeVectors", cameraFrustumEdgeVectors);
			Shader.SetGlobalVector("AngleBetweenRays", new Vector2(angleX, angleY));
			Shader.SetGlobalMatrix("CameraInverseViewMatrix", Camera.main.cameraToWorldMatrix);
			
			//Cannot set bool/floats globally. For simplicity we do it for all computeShaders
			var computeShaders = new[] { SphereTracingShader, BilateralFilterShader, DeferredShader};
			foreach (var computeShader in computeShaders)
			{
				computeShader.SetBool("EnableAmbientOcclusion", EnableAmbientOcclusion);
				computeShader.SetBool("EnableSuperSampling", EnableSuperSampling);
				computeShader.SetBool("EnableGlobalIllumination", EnableGlobalIllumination);
				computeShader.SetFloats("ClippingPlanes", Camera.main.nearClipPlane, Camera.main.farClipPlane);
			}
			
		}

		private void DispatchPass(bool isFirstPass)
		{
			if (isFirstPass)
			{
				//Do first SphereTracing step and write SphereTracingData into textures
				_sphereTracingFKernels[ComputeShaderKernel].Dispatch();
			} else
			{
				//Do kPass SphereTracing step and write SphereTracingData into textures
				_sphereTracingKKernels[ComputeShaderKernel].Dispatch();
			}
			//_sphereTracingData.GenerateMips();
			
			//If ambient occlusion is enabled, calculate AO next
			if (EnableAmbientOcclusion)
			{
				//Calculate AO and write in AmbientOcclusionDrt.RenderTexture
				_sphereTracingAoKernels[ComputeShaderKernel].Dispatch();

				if (EnableCrossBilateralFiltering)
				{
					for (int i = 0; i < FilterSteps; i++)
					{
						//Filter AO Texture
						//Bind textures to read and write and do horizontal filtering
						BilateralFilterShader.SetTexture(_horizontalBilateralFilterKernels[ComputeShaderKernel].Id,
							"AmbientOcclusionTexture", i == 0 ? AmbientOcclusionDrt.RenderTexture : AmbientOcclusionDrt.RenderTexture3);
						BilateralFilterShader.SetTexture(_horizontalBilateralFilterKernels[ComputeShaderKernel].Id,
							"AmbientOcclusionTarget", AmbientOcclusionDrt.RenderTexture2);
						_horizontalBilateralFilterKernels[ComputeShaderKernel].Dispatch();
						//Swap textures and do vertical filtering
						BilateralFilterShader.SetTexture(_verticalBilateralFilterKernels[ComputeShaderKernel].Id,
							"AmbientOcclusionTexture", AmbientOcclusionDrt.RenderTexture2);
						BilateralFilterShader.SetTexture(_verticalBilateralFilterKernels[ComputeShaderKernel].Id,
							"AmbientOcclusionTarget", AmbientOcclusionDrt.RenderTexture3);
						_verticalBilateralFilterKernels[ComputeShaderKernel].Dispatch();
					}
				}
			}
			
			DeferredShader.SetBool("IsFirstPass", isFirstPass);
			//Deferred Rendering step to calculate lightning and finalize image
			_deferredKernels[ComputeShaderKernel].Dispatch();
			
		}
		
		// Update is called once per frame
		private void Update()
		{
			UpdateStLights();
			UpdateStMaterials();
			SetShaderPropertiesPerFrame();

			DispatchPass(true);

			for (int iterativeStep = 0; iterativeStep < IterativeSteps; iterativeStep++)
			{
				//Perform iterative steps for transparency and reflections
				DispatchPass(false);
			}

		}

		private void OnRenderImage(RenderTexture src, RenderTexture dest)
		{
			//Render Texture on Screen
			Graphics.Blit(_deferredOutput, (RenderTexture) null);
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
			if (_deferredOutput != null) DestroyImmediate(_deferredOutput);
			if (_sphereTracingData != null) DestroyImmediate(_sphereTracingData);
			if (AmbientOcclusionDrt.RenderTexture != null) DestroyImmediate(AmbientOcclusionDrt.RenderTexture);
		}
		
		private ComputeKernel[] InitComputeKernels(ComputeShader computeShader, Resolution res, int totalThreadsZ, params string[] kernelNames)
		{
			var ret = new ComputeKernel[kernelNames.Length];
			for (int i = 0; i < ret.Length; i++)
			{
				ret[i].LinkedComputeShader = computeShader;
				ret[i].Name = kernelNames[i];
				ret[i].Id = computeShader.FindKernel(ret[i].Name);
				uint threadGroupX, threadGroupY, threadGroupZ;
				computeShader.GetKernelThreadGroupSizes(ret[i].Id, out threadGroupX,
					out threadGroupY, out threadGroupZ);
				ret[i].ThreadGroupSize = new Vector3Int((int) threadGroupX, (int) threadGroupY, (int) threadGroupZ);
				ret[i].CalculateThreadGroups(res.width, res.height, totalThreadsZ);
			}

			return ret;
		}

		protected struct ComputeKernel
		{
			public ComputeShader LinkedComputeShader;
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

			public void Dispatch()
			{
				LinkedComputeShader.Dispatch(Id, ThreadGroups.x, ThreadGroups.y, ThreadGroups.z);
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

			Shader.SetGlobalInt("LightCount", LightCount);
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

			DeferredShader.SetBuffer(_deferredKernels[ComputeShaderKernel].Id, "LightBuffer", _stLightBuffer);
		}

		#endregion
		
		#region Material

		public StMaterial[] StMaterials;
		private ComputeBuffer _stMaterialBuffer;

		private void InitMaterials()
		{
			_stMaterialBuffer = new ComputeBuffer(StMaterials.Length, StMaterialData.GetSize(), ComputeBufferType.Default);
			_stMaterialBuffer.SetData(StMaterials.Select(x => x.MaterialData).ToArray());

			Shader.SetGlobalInt("MaterialCount", StMaterials.Length);
		}
		
		private void UpdateStMaterials()
		{
			_stMaterialBuffer.SetData(StMaterials.Select(x => x.MaterialData).ToArray());

			DeferredShader.SetBuffer(_deferredKernels[ComputeShaderKernel].Id, "MaterialBuffer", _stMaterialBuffer);
			SphereTracingShader.SetBuffer(_sphereTracingKKernels[ComputeShaderKernel].Id, "MaterialBuffer", _stMaterialBuffer);
			SphereTracingShader.SetBuffer(_sphereTracingAoKernels[ComputeShaderKernel].Id, "MaterialBuffer", _stMaterialBuffer);
		}
		
		#endregion
	}
}