using System.Collections.Generic;
using System.Linq;
using SphereTracing.DeferredRendering;
using SphereTracing.Lights;
using SphereTracing.Materials;
using SphereTracing.Matrices;
using UnityEngine;
using UnityEngine.Rendering;

namespace SphereTracing
{
	public class SphereTracingManager : MonoBehaviour
	{
		private ComputeKernel[] _sphereTracingFKernels;
		private ComputeKernel[] _sphereTracingKKernels;
		private ComputeKernel[] _sphereTracingDownSamplerKernels;
		private ComputeKernel[] _sphereTracingAoKernels;
		private ComputeKernel[] _sphereTracingAoUpSamplerKernels;
		private ComputeKernel[] _horizontalBilateralFilterKernels;
		private ComputeKernel[] _verticalBilateralFilterKernels;
		private ComputeKernel[] _deferredKernels;
		
		private ComputeKernel[] _environmentMapRendererKernels;
		private ComputeKernel[] _environmentMapConvolutionKernels;
		
		private Resolution _targetResolution;
		
		private RenderTexture _deferredOutput;
		private RenderTexture _sphereTracingData;
		private RenderTexture _sphereTracingDataLow;

		private ComputeBuffer _aoSampleBuffer;
		
		#region PublicVariables Adjustable in Editor

		[Header("Dependencies")]
		public ComputeShader SphereTracingShader;
		public ComputeShader SphereTracingDownSampler;
		public ComputeShader AmbientOcclusionShader;
		public ComputeShader AmbientOcclusionUpSampler;
		public ComputeShader BilateralFilterShader;
		public ComputeShader DeferredShader;
		[Space(5)]
		public ComputeShader EnvironmentMapRenderer;
		public ComputeShader EnvironmentMapConvolution;
		public Texture2D BrdfLUT;
		
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
		[Header("Render Settings")]
		public int IterativeSteps = 0;
		public RenderOutput RenderOutput = RenderOutput.Color;
		public Vector3 GammaCorrection = Vector3.one;
		
		[Header("Shadow Settings")]
		public bool EnableShadows = true;
		public bool UseOldShadowTechnique = true;
		[Range(2, 128)]
		public int MaxShadowSteps = 32;
		[Range(2, 128)]
		public float ShadowSoftnessFactor = 10;
		[Range(0, 3)]
		public float ShadowBias = 1;
	
		[Header("Anti Aliasing")]
		[Range(0.001f, 1f)]
		public float RadiusPixel = 0.01f;
		
		[Header("Features")]
		public bool DisableAntiAliasing;
		public int LightCount = 1;
		public Color ClearColor = Color.black;
		[Tooltip("x: Gap Distance, y: Size, z: Depth, w: VisibleRange")]
		public Vector4 PlateTextureSettings = new Vector4(1.0f, .0075f, .0025f, 20f);
		
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
		[Range(0f, Mathf.PI * 2f)]
		public float ConeAngle = 1.0f;
		[Space(10)]
		public bool EnableGlobalIllumination;
		public bool EnableCrossBilateralFiltering;
		[Range(1, 32)]
		public int FilterSteps = 1;

		[Header("Cubemap")]
		public bool EnableCubemap;
		public Vector3 SunPosition = new Vector3(4000.0f, 150.0f, 7000.0f);
		//public Cubemap Cubemap;

		[Header("Cubemap Convolution")]
		public bool RenderCubemapContinuously = false;
		public int CubemapResolution = 1024;
		public int ConvolutionLayerCount = 6;
		public int ConvolutionSampleCount = 6;
        [Range(0,5)]
        public int CubeMapIndex;
		[Space(10)]
		[Tooltip("Control the resolution of ambient occlusion rendering.")]
		public DeferredRenderTarget AmbientOcclusionDrt;

		#endregion

		private RenderTexture _fakeCubemapRenderTexture;
		private RenderTexture _fakeCubemapArrayRenderTexture;
		private Cubemap _environmentMap;
		private CubemapArray _convolutedEnvironmentMapArray;
		
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

			AmbientOcclusionDrt.Init("AmbientOcclusion", _targetResolution, RenderTextureFormat.ARGBFloat, TextureDimension.Tex2DArray, 2);

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

			_sphereTracingDataLow = new RenderTexture(AmbientOcclusionDrt.Resolution.width, AmbientOcclusionDrt.Resolution.height, 0,
				RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear)
			{
				enableRandomWrite = true,
				useMipMap = false,
				autoGenerateMips = false,
				dimension = TextureDimension.Tex2DArray,
				volumeDepth = 6
			};
			_sphereTracingDataLow.Create();

			_fakeCubemapRenderTexture = new RenderTexture(CubemapResolution, CubemapResolution, 0,
				RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear)
			{
				enableRandomWrite = true,
				useMipMap = false,
				autoGenerateMips = false,
				anisoLevel = 0,
				dimension = TextureDimension.Tex2DArray,
				volumeDepth = 6
			};
			_fakeCubemapRenderTexture.Create();
			
			_fakeCubemapArrayRenderTexture = new RenderTexture(CubemapResolution, CubemapResolution, 0,
				RenderTextureFormat.ARGBHalf, RenderTextureReadWrite.Linear)
			{
				enableRandomWrite = true,
				useMipMap = false,
				autoGenerateMips = false,
				anisoLevel = 0,
				dimension = TextureDimension.Tex2DArray,
				volumeDepth = 6 * ConvolutionLayerCount
			};
			_fakeCubemapArrayRenderTexture.Create();

			_environmentMap = new Cubemap(CubemapResolution, TextureFormat.RGBAHalf, false)
			{
				hideFlags = HideFlags.HideAndDontSave,
				wrapMode = TextureWrapMode.Clamp,
				anisoLevel = 0
			};
			
			_convolutedEnvironmentMapArray = new CubemapArray(CubemapResolution, ConvolutionLayerCount, TextureFormat.RGBAHalf, false)
			{
				hideFlags = HideFlags.HideAndDontSave,
				wrapMode = TextureWrapMode.Clamp,
				filterMode = FilterMode.Trilinear,
				anisoLevel = 0
			};

			_sphereTracingFKernels = InitComputeKernels(SphereTracingShader, _targetResolution, 1, "SphereTracingFPassH", "SphereTracingFPassM", "SphereTracingFPassL");
			_sphereTracingKKernels = InitComputeKernels(SphereTracingShader, _targetResolution, 1, "SphereTracingKPassH", "SphereTracingKPassM", "SphereTracingKPassL");
			_sphereTracingDownSamplerKernels = InitComputeKernels(SphereTracingDownSampler, AmbientOcclusionDrt.Resolution, 2, "SphereTracingDownSampleH", "SphereTracingDownSampleM", "SphereTracingDownSampleL");
			_sphereTracingAoKernels = InitComputeKernels(AmbientOcclusionShader, AmbientOcclusionDrt.Resolution, 1, "AmbientOcclusionH", "AmbientOcclusionM", "AmbientOcclusionL");
			_sphereTracingAoUpSamplerKernels = InitComputeKernels(AmbientOcclusionUpSampler, _targetResolution, 2, "AmbientOcclusionUpSampleH", "AmbientOcclusionUpSampleM", "AmbientOcclusionUpSampleL");
			_horizontalBilateralFilterKernels = InitComputeKernels(BilateralFilterShader, _targetResolution, 2, "AOHorizontalH", "AOHorizontalM", "AOHorizontalL");
			_verticalBilateralFilterKernels = InitComputeKernels(BilateralFilterShader, _targetResolution, 2, "AOVerticalH", "AOVerticalM", "AOVerticalL");
			_deferredKernels = InitComputeKernels(DeferredShader, _targetResolution, 1, "DeferredH", "DeferredM", "DeferredL");

			var environmentMapResolution = new Resolution {width = CubemapResolution, height = CubemapResolution};
			//With 6 z Dispatch groups, one for each side of cubemap
			_environmentMapRendererKernels = InitComputeKernels(EnvironmentMapRenderer,environmentMapResolution, 6, "RenderEnvironmentMapH", "RenderEnvironmentMapM", "RenderEnvironmentMapL");
			//With 6 * ConvolutionLayerCount z Dispatch groups. One for each side of cubemap per convoluted cubemap
			_environmentMapConvolutionKernels = InitComputeKernels(EnvironmentMapConvolution, environmentMapResolution, 6 * ConvolutionLayerCount, "ConvoluteEnvironmentMapH", "ConvoluteEnvironmentMapM", "ConvoluteEnvironmentMapL");

			GenerateAmbientOcclusionSamples();
			
			InitLights();
			InitMaterials();
			InitMatrices();
			SetShaderPropertiesOnce();
			
			//At least we have to render environmentmap one
			RenderEnvironmentMap();
		}

		private void GenerateAmbientOcclusionSamples()
		{
			const int samplesPerStep = 360;
			int sampleCount = AmbientOcclusionSamples * samplesPerStep;
			_aoSampleBuffer = new ComputeBuffer(sampleCount, 3 * sizeof(float), ComputeBufferType.Default);
			var samples = new Vector3[sampleCount];
			int c = 0;
			for (int i = 0; i < AmbientOcclusionSamples; i++)
			{
				for (int deg = 0; deg < samplesPerStep; deg++)
				{
					deg *= 360 / samplesPerStep;
					float rad = deg * Mathf.Deg2Rad;
					var sample = Utils.Sampling.HemisphericalFibonacciMapping(i, AmbientOcclusionSamples, rad);
					samples[c] = sample;
					c++;
				}
			}
			_aoSampleBuffer.SetData(samples);
		}
		
		private void SetShaderPropertiesOnce()
		{
			Shader.SetGlobalFloat("AoTargetMip", AmbientOcclusionDrt.TargetMip);
			//Shader.SetGlobalFloat("CubemapMaxMip", Cubemap.mipmapCount);
			Shader.SetGlobalInt("EnvironmentMapResolution", CubemapResolution);
			//Cannot set bool/floats globally. For simplicity we do it for all computeShaders
			var computeShaders = new[] { SphereTracingShader, SphereTracingDownSampler, AmbientOcclusionShader, AmbientOcclusionUpSampler, BilateralFilterShader, DeferredShader};
			foreach (var computeShader in computeShaders)
			{
				computeShader.SetFloats("Resolution", _targetResolution.width, _targetResolution.height);
				computeShader.SetFloats("AoResolution", AmbientOcclusionDrt.Resolution.width, AmbientOcclusionDrt.Resolution.height);
			}
			//Only bind textures once
			foreach (var kernel in _sphereTracingFKernels)
			{
				SphereTracingShader.SetTexture(kernel.Id, "SphereTracingDataTexture", _sphereTracingData);
				SphereTracingShader.SetBuffer(kernel.Id, "MaterialBuffer", _stMaterialBuffer);
				SphereTracingShader.SetBuffer(kernel.Id, "MatrixBuffer", _stMatrixBuffer);
				SphereTracingShader.SetBuffer(kernel.Id, "LightBuffer", _stLightBuffer);
			}
			foreach (var kernel in _sphereTracingKKernels)
			{
				SphereTracingShader.SetTexture(kernel.Id, "SphereTracingDataTexture", _sphereTracingData);
				SphereTracingShader.SetBuffer(kernel.Id, "MaterialBuffer", _stMaterialBuffer);
				SphereTracingShader.SetBuffer(kernel.Id, "MatrixBuffer", _stMatrixBuffer);
				SphereTracingShader.SetBuffer(kernel.Id, "LightBuffer", _stLightBuffer);
			}
			foreach (var kernel in _sphereTracingDownSamplerKernels)
			{
				SphereTracingDownSampler.SetTexture(kernel.Id, "SphereTracingDataTexture", _sphereTracingData);
				SphereTracingDownSampler.SetTexture(kernel.Id, "SphereTracingDataLowTexture", _sphereTracingDataLow);
			}
			foreach (var kernel in _sphereTracingAoKernels)
			{
				AmbientOcclusionShader.SetTexture(kernel.Id, "SphereTracingDataTexture", _sphereTracingDataLow);
				AmbientOcclusionShader.SetTexture(kernel.Id, "AmbientOcclusionTexture", AmbientOcclusionDrt.RenderTexture);
				AmbientOcclusionShader.SetBuffer(kernel.Id, "AoSampleBuffer", _aoSampleBuffer);
				AmbientOcclusionShader.SetBuffer(kernel.Id, "MaterialBuffer", _stMaterialBuffer);
				AmbientOcclusionShader.SetBuffer(kernel.Id, "MatrixBuffer", _stMatrixBuffer);
				AmbientOcclusionShader.SetBuffer(kernel.Id, "LightBuffer", _stLightBuffer);
			}
			foreach (var kernel in _sphereTracingAoUpSamplerKernels)
			{
				AmbientOcclusionUpSampler.SetTexture(kernel.Id, "SphereTracingDataTexture", _sphereTracingData);
				AmbientOcclusionUpSampler.SetTexture(kernel.Id, "SphereTracingDataLowTexture", _sphereTracingDataLow);
				AmbientOcclusionUpSampler.SetTexture(kernel.Id, "AmbientOcclusionTexture", AmbientOcclusionDrt.RenderTexture);
				AmbientOcclusionUpSampler.SetTexture(kernel.Id, "AmbientOcclusionDataHigh", AmbientOcclusionDrt.RenderTexture2);
			}
			foreach (var kernel in _horizontalBilateralFilterKernels)
			{
				BilateralFilterShader.SetTexture(kernel.Id, "SphereTracingDataTexture", _sphereTracingData);
			}
			foreach (var kernel in _verticalBilateralFilterKernels)
			{
				BilateralFilterShader.SetTexture(kernel.Id, "SphereTracingDataTexture", _sphereTracingData);
			}

			foreach (var kernel in _environmentMapRendererKernels)
			{
				EnvironmentMapRenderer.SetTexture(kernel.Id, "FakeCubemapRenderTexture", _fakeCubemapRenderTexture);
			}
			foreach (var kernel in _environmentMapConvolutionKernels)
			{
				EnvironmentMapConvolution.SetTexture(kernel.Id, "EnvironmentMap", _environmentMap);
				EnvironmentMapConvolution.SetTexture(kernel.Id, "FakeCubemapArrayRenderTexture", _fakeCubemapArrayRenderTexture);
			}
			
			foreach (var kernel in _deferredKernels)
			{
				DeferredShader.SetTexture(kernel.Id, "SphereTracingDataTexture", _sphereTracingData);
				DeferredShader.SetTexture(kernel.Id, "AmbientOcclusionTexture", AmbientOcclusionDrt.RenderTexture2);
				DeferredShader.SetTexture(kernel.Id, "DeferredOutputTexture", _deferredOutput);
				//DeferredShader.SetTexture(kernel.Id, "Cubemap", Cubemap);
				//TODO: THIS IS TEMPORARY
				//DeferredShader.SetTexture(kernel.Id, "FakeCubemapRenderTexture", _fakeCubemapRenderTexture);
				DeferredShader.SetTexture(kernel.Id, "EnvironmentMap", _environmentMap);
				//
				DeferredShader.SetTexture(kernel.Id, "ConvolutedEnvironmentMap", _convolutedEnvironmentMapArray);
				DeferredShader.SetTexture(kernel.Id, "BrdfLUT", BrdfLUT);
				DeferredShader.SetBuffer(kernel.Id, "LightBuffer", _stLightBuffer);
				DeferredShader.SetBuffer(kernel.Id, "MaterialBuffer", _stMaterialBuffer);
				DeferredShader.SetBuffer(kernel.Id, "MatrixBuffer", _stMatrixBuffer);
			}
		}

		private void SetShaderPropertiesPerFrame()
		{
			//Note: Materials and Lights are set seperately in respective regions 
			
			//Set Properties global if possible for simplicity
			Shader.SetGlobalFloat("OcclusionExponent", OcclusionExponent);
			Shader.SetGlobalFloat("RadiusPixel", RadiusPixel);
			Shader.SetGlobalFloat("AmbientOcclusionMaxDistance", AmbientOcclusionMaxDistance);
			Shader.SetGlobalFloat("SpecularOcclusionStrength", SpecularOcclusionStrength);
			Shader.SetGlobalFloat("BentNormalFactor", BentNormalFactor);
			Shader.SetGlobalFloat("ConeAngle", ConeAngle);
			Shader.SetGlobalFloat("ShadowSoftnessFactor", ShadowSoftnessFactor);
			Shader.SetGlobalFloat("ShadowBias", ShadowBias);
			Shader.SetGlobalInt("RenderOutput", (int) RenderOutput);
			Shader.SetGlobalInt("SphereTracingSteps", SphereTracingSteps);
			Shader.SetGlobalInt("AmbientOcclusionSamples", AmbientOcclusionSamples);
			Shader.SetGlobalInt("AmbientOcclusionSteps", AmbientOcclusionSteps);
			Shader.SetGlobalInt("ConvolutionLayerCount", ConvolutionLayerCount);
			Shader.SetGlobalInt("SampleCount", ConvolutionSampleCount);
			Shader.SetGlobalInt("MaxShadowSteps", MaxShadowSteps);
			Shader.SetGlobalVector("Time", new Vector4(Time.time, Time.time / 20f, Time.deltaTime, 1f / Time.deltaTime));
			Shader.SetGlobalVector("CameraPos", Camera.main.transform.position);
			Shader.SetGlobalVector("CameraDir", Camera.main.transform.forward);
			Shader.SetGlobalVector("GammaCorrection", GammaCorrection);
			Shader.SetGlobalVector("PlateTextureSettings", PlateTextureSettings);
			Shader.SetGlobalVector("SunPosition", SunPosition);
			Shader.SetGlobalColor("ClearColor", ClearColor);
			Shader.SetGlobalVectorArray("CameraFrustumEdgeVectors", GetCameraFrustumEdgeVectors(Camera.main));
			Shader.SetGlobalMatrix("CameraInverseViewMatrix", Camera.main.cameraToWorldMatrix);
            Shader.SetGlobalInt("CubeMapIndex", CubeMapIndex);
			//Cannot set bool/floats globally. For simplicity we do it for all computeShaders
			var computeShaders = new[] { SphereTracingShader, SphereTracingDownSampler, AmbientOcclusionShader, AmbientOcclusionUpSampler, BilateralFilterShader, DeferredShader};
			foreach (var computeShader in computeShaders)
			{
				computeShader.SetBool("EnableShadows", EnableShadows);
				computeShader.SetBool("UseOldShadowTechnique", UseOldShadowTechnique);
				computeShader.SetBool("EnableAmbientOcclusion", EnableAmbientOcclusion);
				computeShader.SetBool("DisableAntiAliasing", DisableAntiAliasing);
				computeShader.SetBool("EnableGlobalIllumination", EnableGlobalIllumination);
				computeShader.SetBool("EnableCubemap", EnableCubemap);
				computeShader.SetFloats("ClippingPlanes", Camera.main.nearClipPlane, Camera.main.farClipPlane);
			}
			
		}
		
		// Update is called once per frame
		private void Update()
		{
			UpdateStLights();
			UpdateStMaterials();
			UpdateStMatrices();
			SetShaderPropertiesPerFrame();
			
			//Rerender sky to cubemap if we want to rendercontinuously
			if (RenderCubemapContinuously) RenderEnvironmentMap();
			
			//Dispatch first pass
			DispatchPass(true, IterativeSteps == 0);
			
			//Perform iterative steps for transparency and reflections
			for (int iterativeStep = 0; iterativeStep < IterativeSteps; iterativeStep++)
				DispatchPass(false, iterativeStep > IterativeSteps - 1);
		}
		
		private void DispatchPass(bool isFirstPass, bool isLastPass)
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
			_sphereTracingDownSamplerKernels[ComputeShaderKernel].Dispatch();
			
			//If ambient occlusion is enabled, calculate AO next
			if (EnableAmbientOcclusion)
			{
				//Calculate AO and write in AmbientOcclusionDrt.RenderTexture
				_sphereTracingAoKernels[ComputeShaderKernel].Dispatch();
				_sphereTracingAoUpSamplerKernels[ComputeShaderKernel].Dispatch();

				if (EnableCrossBilateralFiltering)
				{
					for (int i = 0; i < FilterSteps; i++)
					{
						//Filter AO Texture
						//Bind textures to read and write and do horizontal filtering
						BilateralFilterShader.SetTexture(_horizontalBilateralFilterKernels[ComputeShaderKernel].Id,
							"AmbientOcclusionTexture", AmbientOcclusionDrt.RenderTexture2);
						BilateralFilterShader.SetTexture(_horizontalBilateralFilterKernels[ComputeShaderKernel].Id,
							"AmbientOcclusionTarget", AmbientOcclusionDrt.RenderTexture3);
						_horizontalBilateralFilterKernels[ComputeShaderKernel].Dispatch();
						//Swap textures and do vertical filtering
						BilateralFilterShader.SetTexture(_verticalBilateralFilterKernels[ComputeShaderKernel].Id,
							"AmbientOcclusionTexture", AmbientOcclusionDrt.RenderTexture3);
						BilateralFilterShader.SetTexture(_verticalBilateralFilterKernels[ComputeShaderKernel].Id,
							"AmbientOcclusionTarget", AmbientOcclusionDrt.RenderTexture2);
						_verticalBilateralFilterKernels[ComputeShaderKernel].Dispatch();
					}
				}
			}
			
			DeferredShader.SetBool("IsFirstPass", isFirstPass);
			DeferredShader.SetBool("IsLastPass", isLastPass);
			//Deferred Rendering step to calculate lightning and finalize image
			_deferredKernels[ComputeShaderKernel].Dispatch();
			
		}

		private void OnRenderImage(RenderTexture src, RenderTexture dest)
		{
			//Render Texture on Screen
			Graphics.Blit(_deferredOutput, (RenderTexture) null);
		}

		private void RenderEnvironmentMap()
		{
			//Render sky into _fakeCubemapRenderTexture
			_environmentMapRendererKernels[ComputeShaderKernel].Dispatch();
			//Copy textureslices of _fakeCubemapRenderTexture into real cubemap
			for (int f = 0; f < 6; f++)
				Graphics.CopyTexture(_fakeCubemapRenderTexture, f, _environmentMap, f);
			
			//Compute convolution of environmentMap and write into _fakeCubemapArrayRenderTexture
			_environmentMapConvolutionKernels[ComputeShaderKernel].Dispatch();
			//Copy textureslices of _fakeCubemapArrayRenderTexture into real cubemapArray
			for (int f = 0; f < 6 * ConvolutionLayerCount; f++)
				Graphics.CopyTexture(_fakeCubemapArrayRenderTexture, f, _convolutedEnvironmentMapArray, f);
		}
		
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
			if (_stMatrixBuffer != null) _stMatrixBuffer.Release();
			if (_aoSampleBuffer != null) _aoSampleBuffer.Release();
			if (_deferredOutput != null) DestroyImmediate(_deferredOutput);
			if (_sphereTracingData != null) DestroyImmediate(_sphereTracingData);
			if (_sphereTracingDataLow != null) DestroyImmediate(_sphereTracingDataLow);
			if (AmbientOcclusionDrt.RenderTexture != null) DestroyImmediate(AmbientOcclusionDrt.RenderTexture);
			if (AmbientOcclusionDrt.RenderTexture2 != null) DestroyImmediate(AmbientOcclusionDrt.RenderTexture2);
			if (AmbientOcclusionDrt.RenderTexture3 != null) DestroyImmediate(AmbientOcclusionDrt.RenderTexture3);
			if (_fakeCubemapRenderTexture != null) DestroyImmediate(_fakeCubemapRenderTexture);
			if (_fakeCubemapArrayRenderTexture != null) DestroyImmediate(_fakeCubemapArrayRenderTexture);
			if (_environmentMap != null) DestroyImmediate(_environmentMap);
			if (_convolutedEnvironmentMapArray != null) DestroyImmediate(_convolutedEnvironmentMapArray);
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
			Shader.SetGlobalBuffer("LightBuffer", _stLightBuffer);
		}

		public void RegisterStLight(StLight stLight)
		{
			if (_stLights != null && _stLights.All(item => item.GetInstanceID() != stLight.GetInstanceID())) _stLights.Add(stLight);
		}

		public void CleanStLights()
		{
			_stLights.RemoveAll(lights => lights == null || !lights.IsActive);
		}

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

			//DeferredShader.SetBuffer(_deferredKernels[ComputeShaderKernel].Id, "LightBuffer", _stLightBuffer);
			Shader.SetGlobalInt("LightCount", _stLights.Count);
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
			Shader.SetGlobalBuffer("MaterialBuffer", _stMaterialBuffer);
		}
		
		private void UpdateStMaterials()
		{
			_stMaterialBuffer.SetData(StMaterials.Select(x => x.MaterialData).ToArray());

			//DeferredShader.SetBuffer(_deferredKernels[ComputeShaderKernel].Id, "MaterialBuffer", _stMaterialBuffer);
			//SphereTracingShader.SetBuffer(_sphereTracingKKernels[ComputeShaderKernel].Id, "MaterialBuffer", _stMaterialBuffer);
			//AmbientOcclusionShader.SetBuffer(_sphereTracingAoKernels[ComputeShaderKernel].Id, "MaterialBuffer", _stMaterialBuffer);
		}
		
		#endregion
		
		#region Matrices


		public int MatrixCount;
		
		private StMatrixData[] _stMatrixData;
		private List<StMatrix> _stMatrices;
		private ComputeBuffer _stMatrixBuffer;

		private void InitMatrices()
		{
			_stMatrixData = new StMatrixData[MatrixCount];
			_stMatrixBuffer = new ComputeBuffer(MatrixCount, StMatrixData.GetSize(), ComputeBufferType.Default);
			_stMatrixBuffer.SetData(_stMatrixData);
			if (_stMatrices == null) _stMatrices = new List<StMatrix>();

			Shader.SetGlobalInt("MatrixCount", MatrixCount);
			Shader.SetGlobalBuffer("MatrixBuffer", _stMatrixBuffer);
		}

		public void RegisterStMatrix(StMatrix stMatrix)
		{
			if (_stMatrices != null && _stMatrices.All(item => item.GetInstanceID() != stMatrix.GetInstanceID())) _stMatrices.Add(stMatrix);
		}

		public void CleanStMatrices()
		{
			_stMatrices.RemoveAll(matrices => matrices == null || !matrices.IsActive);
		}

		private void UpdateStMatrices()
		{
			var i = 0;

			foreach (var stMatrix in _stMatrices)
			{
				_stMatrixData[i] = stMatrix.GetStMatrixData();
				i++;
				if (i >= _stMatrixData.Length)
				{
					if (i > _stMatrixData.Length) Debug.LogWarning("There are more matrices in the scene than the matrix buffer can store."); 
					break; 
				}
			}

			_stMatrixBuffer.SetData(_stMatrixData);

			//DeferredShader.SetBuffer(_deferredKernels[ComputeShaderKernel].Id, "MatrixBuffer", _stMatrixBuffer);
			//Shader.SetGlobalBuffer("MatrixBuffer", _stMatrixBuffer);
			Shader.SetGlobalInt("MatrixCount", _stMatrices.Count);
		}

		#endregion
	}
}