using UnityEditor;
using UnityEngine;

namespace Utils
{
	[ExecuteInEditMode]
	public class HideToolGizmos : MonoBehaviour
	{
		private void OnEnable() { Tools.hidden = true; }

		private void OnDisable() { Tools.hidden = false; }
	}
}