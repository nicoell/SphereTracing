using UnityEngine;

namespace SphereTracing.Matrices
{
	public struct StMatrixData
	{
		public Matrix4x4 Matrix;
		
		/// <summary>
		/// Returns the size of the struct in Bytes.
		/// </summary>
		/// <remarks>Adjust when changing struct.</remarks>
		/// <returns></returns>
		public static int GetSize()
		{
			return 4 * 4 * sizeof(float);
		}
	}
	
	public class StMatrix : MonoBehaviour
	{
		[HideInInspector]
		public bool IsActive = true;
		public SphereTracingManager SphereTracingManager;

		private StMatrixData _stMatrixData;

		public StMatrixData GetStMatrixData()
		{
			_stMatrixData.Matrix = transform.localToWorldMatrix;
			_stMatrixData.Matrix.m03 = -_stMatrixData.Matrix.m03;
			_stMatrixData.Matrix.m13 = -_stMatrixData.Matrix.m13;
			_stMatrixData.Matrix.m23 = -_stMatrixData.Matrix.m23;
			return _stMatrixData;
		}

		protected void Start()
		{
			IsActive = true;
			SphereTracingManager.RegisterStMatrix(this);
		}

		protected void OnDisable()
		{
			IsActive = false;
			SphereTracingManager.CleanStMatrices();
		}
		
		protected void OnEnable()
		{
			if (IsActive) return;
			IsActive = true;
			SphereTracingManager.RegisterStMatrix(this);
		}

		protected void OnDestroy()
		{
			IsActive = false;
			SphereTracingManager.CleanStMatrices();
		}
	}
}