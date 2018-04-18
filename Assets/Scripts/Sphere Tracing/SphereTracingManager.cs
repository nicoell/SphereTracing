using UnityEngine;
using UnityEngine.Analytics;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class SphereTracingManager : MonoBehaviour
{
	private int _sphereTracingKernel;
	private MaterialPropertyBlock _targetRendererProperties;
	private RenderTexture _targetRenderTextureArray;
	private Resolution _targetResolution;
	private int _threadGroupX, _threadGroupY, _threadGroupZ;
	public Mesh QuadMesh;

	[Range(0, 2)]
	public int RenderMode;
	public ComputeShader SphereTracingShader;
	public Material TargetRendererMaterial;

	[Range(-50, 50)]
	public float CameraDistance = 5f;
	[Range(0.1f, 3f)]
	public float FOV = 1f;


	// Use this for initialization
	private void Start()
	{
		_targetRendererProperties = new MaterialPropertyBlock();

		_targetResolution = Screen.currentResolution;

		_targetRenderTextureArray = new RenderTexture(_targetResolution.width, _targetResolution.height, 0,
			RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear)
		{
			dimension = TextureDimension.Tex2DArray,
			volumeDepth = 3,
			enableRandomWrite = true
		};
		_targetRenderTextureArray.Create();

		_sphereTracingKernel = SphereTracingShader.FindKernel("CSMain");

		uint threadGroupX, threadGroupY, threadGroupZ;
		SphereTracingShader.GetKernelThreadGroupSizes(_sphereTracingKernel, out threadGroupX,
			out threadGroupY, out threadGroupZ);

		_threadGroupX = (int) (_targetResolution.width / threadGroupX);
		_threadGroupY = (int) (_targetResolution.height / threadGroupY);
		_threadGroupZ = 1;

		_targetRendererProperties.SetTexture("SphereTracingArray", _targetRenderTextureArray);
		Shader.SetGlobalTexture("SphereTracingArray", _targetRenderTextureArray);
	}

	// Update is called once per frame
	private void Update()
	{
		TargetRendererMaterial.SetInt("ArrayIndex", RenderMode);
		
		
		Shader.SetGlobalInt("ArrayIndex", RenderMode);

		RunSphereTracing();
		Graphics.DrawMesh(QuadMesh, Matrix4x4.identity, TargetRendererMaterial, 0, Camera.current, 0,
			_targetRendererProperties);
	}

	private void RunSphereTracing()
	{
		SphereTracingShader.SetFloat("CameraDistance", CameraDistance);
		SphereTracingShader.SetFloat("FOV", FOV);
		SphereTracingShader.SetFloat("Width", _targetResolution.width);
		SphereTracingShader.SetFloat("Height", _targetResolution.height);
		SphereTracingShader.SetTexture(_sphereTracingKernel, "SphereTracingArray", _targetRenderTextureArray);
		SphereTracingShader.Dispatch(_sphereTracingKernel, _threadGroupX, _threadGroupY, _threadGroupZ);
	}
}