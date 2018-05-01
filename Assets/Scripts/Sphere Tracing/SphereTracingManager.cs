using UnityEngine;

[ExecuteInEditMode]
public class SphereTracingManager : MonoBehaviour
{
	private int _sphereTracingKernel;
	private RenderTexture _targetRenderTexture;
	private Resolution _targetResolution;
	private int _threadGroupX, _threadGroupY, _threadGroupZ;
	public ComputeShader SphereTracingShader;
	[Range(2, 1024)]
	public int SphereTracingSteps = 32;

	// Use this for initialization
	private void Start()
	{
		// Create Render Texture
		_targetResolution = Screen.currentResolution;
		_targetRenderTexture = new RenderTexture(_targetResolution.width, _targetResolution.height, 0,
			RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear)
		{
			enableRandomWrite = true
		};
		_targetRenderTexture.Create();

		// Get Kernel and ThreadGroupSizes of Compute Shader
		_sphereTracingKernel = SphereTracingShader.FindKernel("CSMain");
		uint threadGroupX, threadGroupY, threadGroupZ;
		SphereTracingShader.GetKernelThreadGroupSizes(_sphereTracingKernel, out threadGroupX,
			out threadGroupY, out threadGroupZ);
		_threadGroupX = (int) (_targetResolution.width / threadGroupX);
		_threadGroupY = (int) (_targetResolution.height / threadGroupY);
		_threadGroupZ = 1;

		//Set resolution and texture in ComputeShader
		SphereTracingShader.SetFloats("Resolution", _targetResolution.width, _targetResolution.height);
		SphereTracingShader.SetTexture(_sphereTracingKernel, "SphereTracingTexture", _targetRenderTexture);
	}

	// Update is called once per frame
	private void Update()
	{
		SphereTracingShader.SetTexture(_sphereTracingKernel, "SphereTracingTexture", _targetRenderTexture);
		SphereTracingShader.SetVectorArray("CameraFrustumEdgeVectors", GetCameraFrustumEdgeVectors(Camera.main));
		SphereTracingShader.SetMatrix("CameraInverseViewMatrix", Camera.main.cameraToWorldMatrix);
		SphereTracingShader.SetVector("CameraPos", Camera.main.transform.position);
		
		SphereTracingShader.SetInt("SphereTracingSteps", SphereTracingSteps);
		
		SphereTracingShader.Dispatch(_sphereTracingKernel, _threadGroupX, _threadGroupY, _threadGroupZ);
	}

	private void OnRenderImage(RenderTexture src, RenderTexture dest)
	{
		//Render Texture on Screen
		Graphics.Blit(_targetRenderTexture, (RenderTexture) null);
	}

	private void OnDrawGizmos()
	{
		Gizmos.DrawSphere(Vector3.zero, 3f);
	}

	private void OnDrawGizmosSelected()
	{
		//Draw Camera Frustum Edge Vectors
		var cameraFrustumEdgeVectors = GetCameraFrustumEdgeVectors(Camera.main);
		foreach (var edge in cameraFrustumEdgeVectors)
		{
			
			Gizmos.DrawRay(Camera.main.transform.position, Camera.main.worldToCameraMatrix.MultiplyVector(edge));
		}
	}

	private static Vector4[] GetCameraFrustumEdgeVectors(Camera camera)
	{
		var frustumVectors = new Vector4[4];
		float tanFov = Mathf.Tan(camera.fieldOfView * 0.5f * Mathf.Deg2Rad);
		var right = Vector3.right * tanFov * camera.aspect;
		var top = Vector3.up * tanFov;

		frustumVectors[0] = -Vector3.forward - right + top; //TopLeft
		frustumVectors[1] = -Vector3.forward + right + top; //TopRight
		frustumVectors[2] = -Vector3.forward + right - top; //BottomRight
		frustumVectors[3] = -Vector3.forward - right - top; //BottomLeft

		return frustumVectors;
	}
}