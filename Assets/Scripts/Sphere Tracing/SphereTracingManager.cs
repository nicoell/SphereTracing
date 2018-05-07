using UnityEngine;

[ExecuteInEditMode]
public class SphereTracingManager : MonoBehaviour
{
	private ComputeKernel[] _computeKernels;
	private RenderTexture _targetRenderTexture;
	private Resolution _targetResolution;
	public bool UseCustomResolution;
	public Vector2Int CustomResolution;
	[Tooltip("Kernels have a different ThreadGroupSizes. 0: High; 1: Mid; 2: Low Size.")]
	[Range(0, 2)]
	public int ComputeShaderKernel;
	public ComputeShader SphereTracingShader;
	[Range(2, 1024)]
	public int SphereTracingSteps = 32;

// Use this for initialization
	private void Start()
	{
		// Create Render Texture
		if (UseCustomResolution)
		{
			_targetResolution = new Resolution
			{
				width = CustomResolution.x,
				height = CustomResolution.y
			};
		} else
		{
			_targetResolution = Screen.currentResolution;
		}
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
	}

	// Update is called once per frame
	private void Update()
	{
		SphereTracingShader.SetTexture(_computeKernels[ComputeShaderKernel].Id, "SphereTracingTexture", _targetRenderTexture);
		SphereTracingShader.SetVectorArray("CameraFrustumEdgeVectors", GetCameraFrustumEdgeVectors(Camera.main));
		SphereTracingShader.SetMatrix("CameraInverseViewMatrix", Camera.main.cameraToWorldMatrix);
		SphereTracingShader.SetVector("CameraPos", Camera.main.transform.position);
		SphereTracingShader.SetVector("Time", new Vector4(Time.time, Time.time / 20f, Time.deltaTime, 1f / Time.deltaTime));

		SphereTracingShader.SetInt("SphereTracingSteps", SphereTracingSteps);

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

		frustumVectors[0] = -Vector3.forward - right + top; //TopLeft
		frustumVectors[1] = -Vector3.forward + right + top; //TopRight
		frustumVectors[2] = -Vector3.forward + right - top; //BottomRight
		frustumVectors[3] = -Vector3.forward - right - top; //BottomLeft

		return frustumVectors;
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

	private void OnDestroy()
	{
		DestroyImmediate(_targetRenderTexture);
	}
}