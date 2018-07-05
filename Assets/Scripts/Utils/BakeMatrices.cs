using UnityEngine;

namespace Utils
{
	public class BakeMatrices : MonoBehaviour
	{
		public string[] MatrixNames;
		public Vector3[] Rotations;
		public Vector3[] Transforms;

		public void PrintHlslMatrices()
		{
			if (Transforms.Length != Rotations.Length || Rotations.Length != MatrixNames.Length) return;

			var hlslOut = "";

			var txm = new Matrix4x4[Transforms.Length];
			for (var i = 0; i < Transforms.Length; i++)
			{
				var t = -Transforms[i];
				var r = Rotations[i];
				var tm = new Matrix4x4(new Vector4(1f, 0f, 0f, t.x), new Vector4(0f, 1f, 0f, t.y),
					new Vector4(0f, 0f, 1f, t.z), new Vector4(0f, 0f, 0f, 1f));
				if (Mathf.Abs(r.magnitude) < Mathf.Epsilon) txm[i] = tm;

				var rx = new Matrix4x4(new Vector4(1f, 0f, 0f, 0f),
					new Vector4(0f, Mathf.Cos(r.x), -Mathf.Sin(r.x), 0f),
					new Vector4(0f, Mathf.Sin(r.x), Mathf.Cos(r.x), 0f), new Vector4(0f, 0f, 0f, 1f));

				txm[i] = rx * tm;

				hlslOut += "static const float4x4 " + MatrixNames[i] + " =\nfloat4x4(";
				for (var row = 0; row < 4; row++)
				{
					var vrow = txm[i].GetColumn(row);
					hlslOut += vrow.x + ", " + vrow.y + ", " + vrow.z + ", " + vrow.w;
					hlslOut += row < 3 ? ", \n" : "); \n \n";
				}
			}

			Debug.Log(hlslOut);
		}
	}
}