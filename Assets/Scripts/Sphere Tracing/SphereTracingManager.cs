using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class SphereTracingManager : MonoBehaviour
{
	private int _sphereTracingKernel;
	private MaterialPropertyBlock _targetRendererProperties;
	private RenderTexture _targetRenderTextureArray;
	private Resolution _targetResolution;
	private int _threadGroupX, _threadGroupY, _threadGroupZ;

	[Range(0.1f, 3f)]
	public float FOV = 1f;
	public Mesh QuadMesh;

	[Range(0, 2)]
	public int RenderMode;
	public ComputeShader SphereTracingShader;
	public Material TargetRendererMaterial;

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
		Graphics.DrawMesh(QuadMesh, Matrix4x4.identity, TargetRendererMaterial, 0, Camera.main, 0,
			_targetRendererProperties);
	}

	private void RunSphereTracing()
	{
		SphereTracingShader.SetVector("CameraPos", Camera.main.transform.position);
		SphereTracingShader.SetMatrix("CameraRot", Matrix4x4.Rotate(Camera.main.transform.rotation));
		SphereTracingShader.SetFloat("FOV", FOV);
		SphereTracingShader.SetFloat("Width", _targetResolution.width);
		SphereTracingShader.SetFloat("Height", _targetResolution.height);
		SphereTracingShader.SetTexture(_sphereTracingKernel, "SphereTracingArray", _targetRenderTextureArray);
		SphereTracingShader.Dispatch(_sphereTracingKernel, _threadGroupX, _threadGroupY, _threadGroupZ);
	}
}